//
//  Created by Cédric Luthi on 25.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerView.h"
#import "RTSActivityGestureRecognizer.h"

#import <TransitionKit/TransitionKit.h>
#import <libextobjc/EXTScope.h>

NSString * const RTSMediaPlayerPlaybackDidFinishNotification = @"RTSMediaPlayerPlaybackDidFinish";
NSString * const RTSMediaPlayerPlaybackStateDidChangeNotification = @"RTSMediaPlayerPlaybackStateDidChange";
NSString * const RTSMediaPlayerNowPlayingMediaDidChangeNotification = @"RTSMediaPlayerNowPlayingMediaDidChange";

NSString * const RTSMediaPlayerWillShowControlOverlaysNotification = @"RTSMediaPlayerWillShowControlOverlays";
NSString * const RTSMediaPlayerDidShowControlOverlaysNotification = @"RTSMediaPlayerDidShowControlOverlays";
NSString * const RTSMediaPlayerWillHideControlOverlaysNotification = @"RTSMediaPlayerWillHideControlOverlays";
NSString * const RTSMediaPlayerDidHideControlOverlaysNotification = @"RTSMediaPlayerDidHideControlOverlays";


NSString * const RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey = @"Reason";
NSString * const RTSMediaPlayerPlaybackDidFinishErrorUserInfoKey = @"Error";

NSString * const RTSMediaPlayerPreviousPlaybackStateUserInfoKey = @"PreviousPlaybackState";

@interface RTSMediaPlayerController () <RTSMediaPlayerControllerDataSource, UIGestureRecognizerDelegate>

@property (readonly) TKStateMachine *stateMachine;
@property (readwrite) TKState *idleState;
@property (readwrite) TKState *readyState;
@property (readwrite) TKState *playingState;
@property (readwrite) TKState *stalledState;
@property (readwrite) TKEvent *loadContentURLEvent;
@property (readwrite) TKEvent *loadSuccessEvent;
@property (readwrite) TKEvent *playEvent;
@property (readwrite) TKEvent *pauseEvent;
@property (readwrite) TKEvent *endEvent;
@property (readwrite) TKEvent *stopEvent;
@property (readwrite) TKEvent *stallEvent;
@property (readwrite) TKEvent *resetEvent;

@property (readwrite) RTSMediaPlaybackState playbackState;
@property (readwrite) AVPlayer *player;
@property (readwrite) id periodicTimeObserver;
@property (readwrite) CMTime previousPlaybackTime;

@property (readonly) RTSMediaPlayerView *playerView;

@property (readonly) dispatch_source_t idleTimer;

@end

@implementation RTSMediaPlayerController

@synthesize player = _player;
@synthesize view = _view;
@synthesize playbackState = _playbackState;
@synthesize stateMachine = _stateMachine;
@synthesize idleTimer = _idleTimer;

#pragma mark - Initialization

- (instancetype) init
{
	return [self initWithContentURL:[NSURL URLWithString:nil]];
}

- (instancetype) initWithContentURL:(NSURL *)contentURL
{
	return [self initWithContentIdentifier:contentURL.absoluteString dataSource:self];
}

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	if (!(self = [super init]))
		return nil;
	
	_identifier = identifier;
	_dataSource = dataSource;
	
	_previousPlaybackTime = kCMTimeInvalid;
	
	[self.stateMachine activate];
	
	return self;
}

- (void) dealloc
{
	[self stop];
	self.player = nil;
}

#pragma mark - RTSMediaPlayerControllerDataSource 

// Used when initialized with `initWithContentURL:`
- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *contentURL, NSError *error))completionHandler
{
	if (!identifier)
		@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Trying to play a media with a nil identifier." userInfo:nil];
	
	completionHandler([NSURL URLWithString:identifier], nil);
}

#pragma mark - Loading

static const NSString *ResultKey = @"Result";

static NSDictionary * SuccessErrorInfo(id result)
{
	return @{ ResultKey: result };
}

static NSDictionary * ErrorUserInfo(NSError *error, NSString *failureReason)
{
	NSDictionary *userInfo = @{ NSLocalizedFailureReasonErrorKey: failureReason ?: @"Unknown failure reason.",
	                            NSLocalizedDescriptionKey: @"An unknown error occured." };
	NSError *unknownError = [NSError errorWithDomain:@"RTSMediaPlayerErrorDomain" code:0 userInfo:userInfo];
	return @{ RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey: @(RTSMediaFinishReasonPlaybackError),
	          RTSMediaPlayerPlaybackDidFinishErrorUserInfoKey: error ?: unknownError };
}

- (TKStateMachine *) stateMachine
{
	if (_stateMachine)
		return _stateMachine;
	
	TKStateMachine *stateMachine = [TKStateMachine new];
	
	if ([[[[NSProcessInfo processInfo] environment] objectForKey:@"RTSMEDIAPLAYER_DEBUG_STATE_MACHINE"] boolValue])
	{
		[[NSNotificationCenter defaultCenter] addObserverForName:TKStateMachineDidChangeStateNotification object:stateMachine queue:[NSOperationQueue new] usingBlock:^(NSNotification *notification) {
			TKTransition *transition = notification.userInfo[TKStateMachineDidChangeStateTransitionUserInfoKey];
			NSLog(@"(%@) ----%@----> (%@)", transition.sourceState.name, transition.event.name, transition.destinationState.name);
			if (transition.userInfo)
			{
				NSLog(@"UserInfo: %@", transition.userInfo);
			}
		}];
	}
	
	TKState *idle = [TKState stateWithName:@"Idle"];
	TKState *loadingContentURL = [TKState stateWithName:@"Loading Content URL"];
	TKState *loadingAsset = [TKState stateWithName:@"Loading Asset"];
	TKState *loadingPlayerItem = [TKState stateWithName:@"Loading Player Item"];
	TKState *ready = [TKState stateWithName:@"Ready"];
	TKState *playing = [TKState stateWithName:@"Playing"];
	TKState *paused = [TKState stateWithName:@"Paused"];
	TKState *stalled = [TKState stateWithName:@"Stalled"];
	[stateMachine addStates:@[ idle, loadingContentURL, loadingAsset, loadingPlayerItem, ready, playing, paused, stalled ]];
	stateMachine.initialState = idle;
	
	TKEvent *loadContentURL = [TKEvent eventWithName:@"Load Content URL" transitioningFromStates:@[ idle ] toState:loadingContentURL];
	TKEvent *loadAsset = [TKEvent eventWithName:@"Load Asset" transitioningFromStates:@[ loadingContentURL ] toState:loadingAsset];
	TKEvent *loadPlayerItem = [TKEvent eventWithName:@"Load Player Item" transitioningFromStates:@[ loadingAsset ] toState:loadingPlayerItem];
	TKEvent *loadSuccess = [TKEvent eventWithName:@"Load Success" transitioningFromStates:@[ loadingPlayerItem ] toState:ready];
	TKEvent *play = [TKEvent eventWithName:@"Play" transitioningFromStates:@[ ready, paused, stalled ] toState:playing];
	TKEvent *pause = [TKEvent eventWithName:@"Pause" transitioningFromStates:@[ playing ] toState:paused];
	TKEvent *end = [TKEvent eventWithName:@"End" transitioningFromStates:@[ playing ] toState:ready];
	TKEvent *stall = [TKEvent eventWithName:@"Stall" transitioningFromStates:@[ playing ] toState:stalled];
	NSMutableSet *allStatesButIdle = [NSMutableSet setWithSet:stateMachine.states];
	[allStatesButIdle removeObject:idle];
	TKEvent *reset = [TKEvent eventWithName:@"Reset" transitioningFromStates:[allStatesButIdle allObjects] toState:idle];
	
	[stateMachine addEvents:@[ loadContentURL, loadAsset, loadPlayerItem, loadSuccess, play, pause, end, stall, reset ]];
	
	@weakify(self)
	
	[idle setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		self.playbackState = RTSMediaPlaybackStateIdle;
	}];
	
	[idle setDidExitStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		self.playbackState = RTSMediaPlaybackStatePreparing;
	}];
	
	[ready setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		self.playbackState = RTSMediaPlaybackStateReady;
	}];
	
	[playing setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		self.playbackState = RTSMediaPlaybackStatePlaying;
	}];
	
	[paused setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		self.playbackState = RTSMediaPlaybackStatePaused;
	}];
	
	[stalled setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		self.playbackState = RTSMediaPlaybackStateStalled;
	}];
	
	[end setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		[self postNotificationName:RTSMediaPlayerPlaybackDidFinishNotification userInfo:transition.userInfo];
	}];
	
	[loadContentURL setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		if (!self.dataSource)
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"RTSMediaPlayerController dataSource can not be nil." userInfo:nil];
		
		[self.dataSource mediaPlayerController:self contentURLForIdentifier:self.identifier completionHandler:^(NSURL *contentURL, NSError *error) {
			if (contentURL)
			{
				[self fireEvent:loadAsset userInfo:SuccessErrorInfo(contentURL)];
			}
			else
			{
				[self fireEvent:self.resetEvent userInfo:ErrorUserInfo(error, @"The RTSMediaPlayerControllerDataSource implementation returned a nil contentURL and a nil error.")];
			}
		}];
	}];
	
	[loadAsset setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		NSURL *contentURL = transition.userInfo[ResultKey];
		AVURLAsset *asset = [AVURLAsset URLAssetWithURL:contentURL options:@{ AVURLAssetPreferPreciseDurationAndTimingKey: @(YES) }];
		static NSString *assetStatusKey = @"duration";
		[asset loadValuesAsynchronouslyForKeys:@[ assetStatusKey ] completionHandler:^{
			NSError *valueStatusError = nil;
			AVKeyValueStatus status = [asset statusOfValueForKey:assetStatusKey error:&valueStatusError];
			if (status == AVKeyValueStatusLoaded)
			{
				[self fireEvent:loadPlayerItem userInfo:SuccessErrorInfo(asset)];
			}
			else
			{
				[self fireEvent:self.resetEvent userInfo:ErrorUserInfo(valueStatusError, @"The `statusOfValueForKey:error:` method did not return an error.")];
			}
		}];
	}];
	
	[loadPlayerItem setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		AVAsset *asset = transition.userInfo[ResultKey];
		self.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
		self.playerView.player = self.player;
		// The player observes its "currentItem.status" keyPath, see callback in `observeValueForKeyPath:ofObject:change:context:`
	}];
	
	[loadSuccess setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		[self registerPeriodicTimeObserver];
		if (self.playWhenReady)
			[self play];
	}];
	
	[reset setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		NSDictionary *userInfo = transition.userInfo ?: @{ RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey: @(RTSMediaFinishReasonUserExited) };
		[self postNotificationName:RTSMediaPlayerPlaybackDidFinishNotification userInfo:userInfo];
		
		self.playerView.player = nil;
		self.player = nil;
	}];
	
	self.idleState = idle;
	self.readyState = ready;
	self.playingState = playing;
	self.stalledState = stalled;
	
	self.loadContentURLEvent = loadContentURL;
	self.loadSuccessEvent = loadSuccess;
	self.playEvent = play;
	self.pauseEvent = pause;
	self.endEvent = end;
	self.stallEvent = stall;
	self.resetEvent = reset;
	
	_stateMachine = stateMachine;
	
	return _stateMachine;
}

- (void) fireEvent:(TKEvent *)event userInfo:(NSDictionary *)userInfo
{
	NSError *error;
	BOOL success = [self.stateMachine fireEvent:event userInfo:userInfo error:&error];
	if (!success)
		NSLog(@"Transition Error: %@", error.localizedFailureReason);
}

#pragma mark - Notifications

- (void) postNotificationName:(NSString *)notificationName userInfo:(NSDictionary *)userInfo
{
	NSNotification *notification = [NSNotification notificationWithName:notificationName object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:NO];
}

#pragma mark - Playback

- (void) play
{
	if (self.player)
	{
		[self.player play];
	}
	else
	{
		self.playWhenReady = YES;
		[self prepareToPlay];
	}
}

- (void) pause
{
	if (self.player)
	{
		[self.player pause];
	}
	else
	{
		self.playWhenReady = NO;
	}
}

- (void) prepareToPlay
{
	[self fireEvent:self.loadContentURLEvent userInfo:nil];
}

- (void) playIdentifier:(NSString *)identifier
{
	if (![self.identifier isEqualToString:identifier])
	{
		[self stop];
		self.identifier = identifier;
	}
	
	[self play];
}

- (void) stop
{
	if (![self.stateMachine.currentState isEqual:self.idleState])
	{
		[self fireEvent:self.resetEvent userInfo:nil];
	}
}

- (void) seekToTime:(NSTimeInterval)time
{
	[self.player seekToTime:CMTimeMakeWithSeconds(time, 1000) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:NULL];
}

- (RTSMediaPlaybackState) playbackState
{
	@synchronized(self)
	{
		return _playbackState;
	}
}

- (void) setPlaybackState:(RTSMediaPlaybackState)playbackState
{
	@synchronized(self)
	{
		if (_playbackState == playbackState)
			return;
		
		NSDictionary *userInfo = @{ RTSMediaPlayerPreviousPlaybackStateUserInfoKey: @(_playbackState) };
		
		_playbackState = playbackState;
		
		[self postNotificationName:RTSMediaPlayerPlaybackStateDidChangeNotification userInfo:userInfo];
	}
}

#pragma mark - AVPlayer

static const void * const AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

- (AVPlayer *) player
{
	@synchronized(self)
	{
		return _player;
	}
}

- (void) setPlayer:(AVPlayer *)player
{
	@synchronized(self)
	{
		[_player removeObserver:self forKeyPath:@"currentItem.status" context:(void *)AVPlayerItemStatusContext];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
		[_player removeTimeObserver:self.periodicTimeObserver];
		
		_player = player;
		
		[_player addObserver:self forKeyPath:@"currentItem.status" options:0 context:(void *)AVPlayerItemStatusContext];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
	}
}

- (void) registerPeriodicTimeObserver
{
	@weakify(self)
	self.periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 5) queue:dispatch_get_main_queue() usingBlock:^(CMTime playbackTime) {
		@strongify(self)
		if (CMTIME_IS_VALID(self.previousPlaybackTime))
		{
			if (CMTIME_COMPARE_INLINE(self.previousPlaybackTime, ==, playbackTime))
			{
				if (self.player.rate != 0)
				{
					BOOL hasPlayed = CMTIME_COMPARE_INLINE(playbackTime, >, kCMTimeZero);
					BOOL isStalled = [self.stateMachine.currentState isEqual:self.stalledState];
					if (hasPlayed && !isStalled)
						[self fireEvent:self.stallEvent userInfo:nil];
				}
				else
				{
					[self fireEvent:self.pauseEvent userInfo:nil];
				}
			}
			else if (![self.stateMachine.currentState isEqual:self.playingState])
			{
				[self fireEvent:self.playEvent userInfo:nil];
			}
		}
		self.previousPlaybackTime = playbackTime;
	}];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == AVPlayerItemStatusContext)
	{
		AVPlayerItem *playerItem = object;
		switch (playerItem.status)
		{
			case AVPlayerItemStatusReadyToPlay:
				[self fireEvent:self.loadSuccessEvent userInfo:SuccessErrorInfo(playerItem)];
				break;
			case AVPlayerItemStatusFailed:
				[self fireEvent:self.resetEvent userInfo:ErrorUserInfo(playerItem.error, @"The AVPlayerItem did report a failed status without an error.")];
				break;
			case AVPlayerItemStatusUnknown:
				break;
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void) playerItemDidPlayToEndTime:(NSNotification *)notification
{
	NSDictionary *userInfo = @{ RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey: @(RTSMediaFinishReasonPlaybackEnded) };
	[self fireEvent:self.endEvent userInfo:userInfo];
}

#pragma mark - View

- (void) attachPlayerToView:(UIView *)containerView
{
	if (self.view.superview)
		[self.view removeFromSuperview];
	
	self.view.frame = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds));
	[containerView insertSubview:self.view atIndex:0];
}

- (UIView *) view
{
	if (!_view)
	{
		_view = [RTSMediaPlayerView new];
		_view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
		UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
		doubleTapGestureRecognizer.numberOfTapsRequired = 2;
		[singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
		
		UIView *activityView = self.activityView ?: _view;
		RTSActivityGestureRecognizer *activityGestureRecognizer = [[RTSActivityGestureRecognizer alloc] initWithTarget:self action:@selector(resetIdleTimer)];
		activityGestureRecognizer.delegate = self;
		[activityView addGestureRecognizer:activityGestureRecognizer];
		
		[_view addGestureRecognizer:singleTapGestureRecognizer];
		[_view addGestureRecognizer:doubleTapGestureRecognizer];
	}
	return _view;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
{
	return [gestureRecognizer isKindOfClass:[RTSActivityGestureRecognizer class]];
}

- (RTSMediaPlayerView *) playerView
{
	return (RTSMediaPlayerView *)self.view;
}

#pragma mark - Overlays

- (void) handleSingleTap
{
	if (!self.playerView.playerLayer.isReadyForDisplay)
		return;
	
	[self toggleOverlays];
}

- (void) setOverlaysVisible:(BOOL)visible
{
	[self postNotificationName:visible ? RTSMediaPlayerWillShowControlOverlaysNotification : RTSMediaPlayerWillHideControlOverlaysNotification userInfo:nil];
	for (UIView *overlayView in self.overlayViews)
	{
		overlayView.hidden = !visible;
	}
	[self postNotificationName:visible ? RTSMediaPlayerDidShowControlOverlaysNotification : RTSMediaPlayerDidHideControlOverlaysNotification userInfo:nil];
}

- (void) toggleOverlays
{
	UIView *firstOverlayView = [self.overlayViews firstObject];
	if (!firstOverlayView)
		return;
	
	[self setOverlaysVisible:firstOverlayView.hidden];
}

- (dispatch_source_t) idleTimer
{
	if (!_idleTimer)
	{
		_idleTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
		@weakify(self)
		dispatch_source_set_event_handler(_idleTimer, ^{
			@strongify(self)
			[self setOverlaysVisible:NO];
		});
		dispatch_resume(_idleTimer);
	}
	return _idleTimer;
}

- (void) resetIdleTimer
{
	int64_t delayInNanoseconds = 5 * NSEC_PER_SEC;
	int64_t toleranceInNanoseconds = 0.1 * NSEC_PER_SEC;
	dispatch_source_set_timer(self.idleTimer, dispatch_time(DISPATCH_TIME_NOW, delayInNanoseconds), DISPATCH_TIME_FOREVER, toleranceInNanoseconds);
}

#pragma mark - Resize Aspect

- (void) handleDoubleTap
{
	if (!self.playerView.playerLayer.isReadyForDisplay)
		return;
	
	[self toggleAspect];
}

- (void) toggleAspect
{
	AVPlayerLayer *playerLayer = self.playerView.playerLayer;
	if ([playerLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect])
		playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	else
		playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
}

@end
