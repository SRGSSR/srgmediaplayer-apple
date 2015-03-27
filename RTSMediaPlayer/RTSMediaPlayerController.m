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
NSString * const RTSMediaPlayerIsReadyToPlayNotification = @"RTSMediaPlayerIsReadyToPlay";

NSString * const RTSMediaPlayerWillShowControlOverlaysNotification = @"RTSMediaPlayerWillShowControlOverlays";
NSString * const RTSMediaPlayerDidShowControlOverlaysNotification = @"RTSMediaPlayerDidShowControlOverlays";
NSString * const RTSMediaPlayerWillHideControlOverlaysNotification = @"RTSMediaPlayerWillHideControlOverlays";
NSString * const RTSMediaPlayerDidHideControlOverlaysNotification = @"RTSMediaPlayerDidHideControlOverlays";


NSString * const RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey = @"Reason";
NSString * const RTSMediaPlayerPlaybackDidFinishErrorUserInfoKey = @"Error";

@interface RTSMediaPlayerController () <RTSMediaPlayerControllerDataSource, UIGestureRecognizerDelegate>

@property (readonly) TKStateMachine *stateMachine;
@property (readwrite) TKState *idleState;
@property (readwrite) TKState *readyToPlayState;
@property (readwrite) TKState *playingState;
@property (readwrite) TKEvent *loadContentURLEvent;
@property (readwrite) TKEvent *playEvent;
@property (readwrite) TKEvent *pauseEvent;
@property (readwrite) TKEvent *stopEvent;
@property (readwrite) TKEvent *stallEvent;
@property (readwrite) TKEvent *resumeEvent;
@property (readwrite) TKEvent *resetEvent;

@property (readwrite) RTSMediaPlaybackState playbackState;
@property (readwrite) AVPlayer *player;
@property (readonly) dispatch_semaphore_t playerItemStatusSemaphore;
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
	_playerItemStatusSemaphore = dispatch_semaphore_create(0);
	
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
static const NSString *ShouldPlayKey = @"ShouldPlay";

static NSDictionary * TransitionUserInfo(TKTransition *transition, id<NSCopying> key, id value)
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:transition.userInfo];
	if (value)
		userInfo[key] = value;
	else
		[userInfo removeObjectForKey:key];
	return [userInfo copy];
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
	TKState *idle = [TKState stateWithName:@"Idle"];
	TKState *loadingContentURL = [TKState stateWithName:@"Loading Content URL"];
	TKState *loadingAsset = [TKState stateWithName:@"Loading Asset"];
	TKState *loadingPlayerItem = [TKState stateWithName:@"Loading Player Item"];
	TKState *readyToPlay = [TKState stateWithName:@"Ready To Play"];
	TKState *playing = [TKState stateWithName:@"Playing"];
	TKState *buffering = [TKState stateWithName:@"Buffering"];
	[stateMachine addStates:@[ idle, loadingContentURL, loadingAsset, loadingPlayerItem, readyToPlay, playing, buffering ]];
	stateMachine.initialState = idle;
	
	TKEvent *loadContentURL = [TKEvent eventWithName:@"Load Content URL" transitioningFromStates:@[ idle ] toState:loadingContentURL];
	TKEvent *loadAsset = [TKEvent eventWithName:@"Load Asset" transitioningFromStates:@[ loadingContentURL ] toState:loadingAsset];
	TKEvent *loadPlayerItem = [TKEvent eventWithName:@"Load Player Item" transitioningFromStates:@[ loadingAsset ] toState:loadingPlayerItem];
	TKEvent *loadSuccess = [TKEvent eventWithName:@"Load Success" transitioningFromStates:@[ loadingPlayerItem	] toState:readyToPlay];
	TKEvent *play = [TKEvent eventWithName:@"Play" transitioningFromStates:@[ readyToPlay ] toState:playing];
	TKEvent *pause = [TKEvent eventWithName:@"Pause" transitioningFromStates:@[ playing, buffering ] toState:readyToPlay];
	TKEvent *stall = [TKEvent eventWithName:@"Stall" transitioningFromStates:@[ playing ] toState:buffering];
	TKEvent *resume = [TKEvent eventWithName:@"Resume" transitioningFromStates:@[ buffering ] toState:playing];
	NSMutableSet *allStatesButIdle = [NSMutableSet setWithSet:stateMachine.states];
	[allStatesButIdle removeObject:idle];
	TKEvent *reset = [TKEvent eventWithName:@"Reset" transitioningFromStates:[allStatesButIdle allObjects] toState:idle];
	
	[stateMachine addEvents:@[ loadContentURL, loadAsset, loadPlayerItem, loadSuccess, play, pause, stall, resume, reset ]];
	
	@weakify(self)
	
	[loadContentURL setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		if (!self.dataSource)
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"RTSMediaPlayerController dataSource can not be nil." userInfo:nil];
		
		self.playbackState = RTSMediaPlaybackStatePendingPlay;
		
		[self.dataSource mediaPlayerController:self contentURLForIdentifier:self.identifier completionHandler:^(NSURL *contentURL, NSError *error) {
			if (contentURL)
			{
				[self.stateMachine fireEvent:loadAsset userInfo:TransitionUserInfo(transition, ResultKey, contentURL) error:NULL];
			}
			else
			{
				[self.stateMachine fireEvent:reset userInfo:ErrorUserInfo(error, @"The RTSMediaPlayerControllerDataSource implementation returned a nil contentURL and a nil error.") error:NULL];
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
				[self.stateMachine fireEvent:loadPlayerItem userInfo:TransitionUserInfo(transition, ResultKey, asset) error:NULL];
			}
			else
			{
				[self.stateMachine fireEvent:reset userInfo:ErrorUserInfo(valueStatusError, @"The `statusOfValueForKey:error:` method did not return an error.") error:NULL];
			}
		}];
	}];
	
	[loadPlayerItem setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		AVAsset *asset = transition.userInfo[ResultKey];
		self.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
		self.playerView.player = self.player;
		dispatch_semaphore_wait(self.playerItemStatusSemaphore, DISPATCH_TIME_FOREVER);
		[self.stateMachine fireEvent:loadSuccess userInfo:TransitionUserInfo(transition, ResultKey, nil) error:NULL];
	}];
	
	[loadSuccess setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		[self registerPeriodicTimeObserver];
		[self postNotificationName:RTSMediaPlayerIsReadyToPlayNotification userInfo:nil];
		if ([transition.userInfo[ShouldPlayKey] boolValue])
			[self.stateMachine fireEvent:play userInfo:nil error:NULL];
	}];
	
	[play setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		[self.player play];
	}];
	
	[pause setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		[self.player pause];
	}];
	
	[reset setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		NSDictionary *userInfo = transition.userInfo ?: @{ RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey: @(RTSMediaFinishReasonUserExited) };
		[self postNotificationName:RTSMediaPlayerPlaybackDidFinishNotification userInfo:userInfo];
		
		self.playerView.player = nil;
		self.player = nil;
	}];
	
	self.idleState = idle;
	self.readyToPlayState = readyToPlay;
	self.playingState = playing;
	
	self.loadContentURLEvent = loadContentURL;
	self.playEvent = play;
	self.pauseEvent = pause;
	self.stallEvent = stall;
	self.resumeEvent = resume;
	self.resetEvent = reset;
	
	_stateMachine = stateMachine;
	
	return _stateMachine;
}

#pragma mark - Notifications

- (void) postNotificationName:(NSString *)notificationName userInfo:(NSDictionary *)userInfo
{
	NSNotification *notification = [NSNotification notificationWithName:notificationName object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
}

#pragma mark - Playback

- (void) play
{
	[self loadAndPlay:YES];
}

- (void) prepareToPlay
{
	[self loadAndPlay:NO];
}

- (void) loadAndPlay:(BOOL)shouldPlay
{
	if ([self.stateMachine.currentState isEqual:self.idleState])
		[self.stateMachine fireEvent:self.loadContentURLEvent userInfo:@{ ShouldPlayKey: @(shouldPlay) } error:NULL];
	else if ([self.stateMachine.currentState isEqual:self.readyToPlayState])
		[self.stateMachine fireEvent:self.playEvent userInfo:nil error:NULL];
}

- (void) playIdentifier:(NSString *)identifier
{
	if (![self.identifier isEqualToString:identifier])
	{
		self.identifier = identifier;
		[self.stateMachine fireEvent:self.resetEvent userInfo:nil error:NULL];
	}
	
	[self loadAndPlay:YES];
}

- (void) pause
{
	[self.stateMachine fireEvent:self.pauseEvent userInfo:nil error:NULL];
}

- (void) stop
{
	[self.stateMachine fireEvent:self.resetEvent userInfo:nil error:nil];
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
		
		_playbackState = playbackState;
		
		[self postNotificationName:RTSMediaPlayerPlaybackStateDidChangeNotification userInfo:nil];
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
					[self.stateMachine fireEvent:self.stallEvent userInfo:nil error:NULL];
				else
					[self.stateMachine fireEvent:self.pauseEvent userInfo:nil error:NULL];
			}
			else if (![self.stateMachine.currentState isEqual:self.playingState])
			{
				[self.stateMachine fireEvent:self.resumeEvent userInfo:nil error:NULL];
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
		if (playerItem.status == AVPlayerItemStatusReadyToPlay)
		{
			dispatch_semaphore_signal(self.playerItemStatusSemaphore);
		}
		else if (playerItem.status == AVPlayerItemStatusFailed)
		{
			[self.stateMachine fireEvent:self.resetEvent userInfo:ErrorUserInfo(playerItem.error, @"The AVPlayerItem did report a failed status without an error.") error:NULL];
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
	[self.stateMachine fireEvent:self.resetEvent userInfo:userInfo error:nil];
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
