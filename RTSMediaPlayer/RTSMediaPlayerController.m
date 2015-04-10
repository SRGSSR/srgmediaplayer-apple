//
//  Created by Cédric Luthi on 25.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerError.h"
#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerView.h"
#import "RTSActivityGestureRecognizer.h"
#import "RTSInvocationRecorder.h"

#import <objc/runtime.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <TransitionKit/TransitionKit.h>
#import <libextobjc/EXTScope.h>

NSString * const RTSMediaPlayerErrorDomain = @"RTSMediaPlayerErrorDomain";

NSString * const RTSMediaPlayerPlaybackDidFailNotification = @"RTSMediaPlayerPlaybackDidFail";
NSString * const RTSMediaPlayerPlaybackStateDidChangeNotification = @"RTSMediaPlayerPlaybackStateDidChange";

NSString * const RTSMediaPlayerWillShowControlOverlaysNotification = @"RTSMediaPlayerWillShowControlOverlays";
NSString * const RTSMediaPlayerDidShowControlOverlaysNotification = @"RTSMediaPlayerDidShowControlOverlays";
NSString * const RTSMediaPlayerWillHideControlOverlaysNotification = @"RTSMediaPlayerWillHideControlOverlays";
NSString * const RTSMediaPlayerDidHideControlOverlaysNotification = @"RTSMediaPlayerDidHideControlOverlays";


NSString * const RTSMediaPlayerPlaybackDidFailErrorUserInfoKey = @"Error";

NSString * const RTSMediaPlayerPreviousPlaybackStateUserInfoKey = @"PreviousPlaybackState";

@interface RTSMediaPlayerController () <RTSMediaPlayerControllerDataSource, UIGestureRecognizerDelegate>

@property (readonly) TKStateMachine *stateMachine;
@property (readwrite) TKState *idleState;
@property (readwrite) TKState *readyState;
@property (readwrite) TKState *playingState;
@property (readwrite) TKState *stalledState;
@property (readwrite) TKEvent *loadEvent;
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
	
	[self.stateMachine activate];
	
	return self;
}

- (void) dealloc
{
	if (![self.stateMachine.currentState isEqual:self.idleState])
	{
		DDLogWarn(@"The media player controller reached dealloc while still active. You should call the `reset` method before reaching dealloc.");
	}
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

static NSDictionary * ErrorUserInfo(NSError *error, NSString *failureReason)
{
	NSDictionary *userInfo = @{ NSLocalizedFailureReasonErrorKey: failureReason ?: @"Unknown failure reason.",
	                            NSLocalizedDescriptionKey: @"An unknown error occured." };
	NSError *unknownError = [NSError errorWithDomain:RTSMediaPlayerErrorDomain code:RTSMediaPlayerErrorUnknown userInfo:userInfo];
	return @{ RTSMediaPlayerPlaybackDidFailErrorUserInfoKey: error ?: unknownError };
}

- (TKStateMachine *) stateMachine
{
	if (_stateMachine)
		return _stateMachine;
	
	TKStateMachine *stateMachine = [TKStateMachine new];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:TKStateMachineDidChangeStateNotification object:stateMachine queue:[NSOperationQueue new] usingBlock:^(NSNotification *notification) {
		TKTransition *transition = notification.userInfo[TKStateMachineDidChangeStateTransitionUserInfoKey];
		DDLogDebug(@"(%@) ---[%@]---> (%@)", transition.sourceState.name, transition.event.name.lowercaseString, transition.destinationState.name);
	}];
	
	TKState *idle = [TKState stateWithName:@"Idle"];
	TKState *preparing = [TKState stateWithName:@"Preparing"];
	TKState *ready = [TKState stateWithName:@"Ready"];
	TKState *playing = [TKState stateWithName:@"Playing"];
	TKState *paused = [TKState stateWithName:@"Paused"];
	TKState *stalled = [TKState stateWithName:@"Stalled"];
	TKState *ended = [TKState stateWithName:@"Ended"];
	[stateMachine addStates:@[ idle, preparing, ready, playing, paused, stalled, ended ]];
	stateMachine.initialState = idle;
	
	TKEvent *load = [TKEvent eventWithName:@"Load" transitioningFromStates:@[ idle ] toState:preparing];
	TKEvent *loadSuccess = [TKEvent eventWithName:@"Load Success" transitioningFromStates:@[ preparing ] toState:ready];
	TKEvent *play = [TKEvent eventWithName:@"Play" transitioningFromStates:@[ ready, paused, stalled, ended ] toState:playing];
	TKEvent *pause = [TKEvent eventWithName:@"Pause" transitioningFromStates:@[ playing ] toState:paused];
	TKEvent *end = [TKEvent eventWithName:@"End" transitioningFromStates:@[ playing ] toState:ended];
	TKEvent *stall = [TKEvent eventWithName:@"Stall" transitioningFromStates:@[ playing ] toState:stalled];
	NSMutableSet *allStatesButIdle = [NSMutableSet setWithSet:stateMachine.states];
	[allStatesButIdle removeObject:idle];
	TKEvent *reset = [TKEvent eventWithName:@"Reset" transitioningFromStates:[allStatesButIdle allObjects] toState:idle];
	
	[stateMachine addEvents:@[ load, loadSuccess, play, pause, end, stall, reset ]];
	
	NSDictionary *states = @{ idle.name:      @(RTSMediaPlaybackStateIdle),
	                          preparing.name: @(RTSMediaPlaybackStatePreparing),
	                          ready.name:     @(RTSMediaPlaybackStateReady),
	                          playing.name:   @(RTSMediaPlaybackStatePlaying),
	                          paused.name:    @(RTSMediaPlaybackStatePaused),
	                          stalled.name:   @(RTSMediaPlaybackStateStalled),
	                          ended.name:     @(RTSMediaPlaybackStateEnded) };
	
	NSCAssert(states.allKeys.count == stateMachine.states.count, @"Must handle all states");
	
	@weakify(self)
	
	[[NSNotificationCenter defaultCenter] addObserverForName:TKStateMachineDidChangeStateNotification object:stateMachine queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		@strongify(self)
		TKTransition *transition = notification.userInfo[TKStateMachineDidChangeStateTransitionUserInfoKey];
		self.playbackState = [states[transition.destinationState.name] integerValue];
	}];
	
	[idle setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		self.previousPlaybackTime = kCMTimeInvalid;
		self.player = (AVPlayer *)[[RTSInvocationRecorder alloc] initWithTargetClass:[AVPlayer class]];
	}];
	
	[load setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		if (!self.dataSource)
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"RTSMediaPlayerController dataSource can not be nil." userInfo:nil];
		
		[self.dataSource mediaPlayerController:self contentURLForIdentifier:self.identifier completionHandler:^(NSURL *contentURL, NSError *error) {
			if (contentURL)
			{
				DDLogInfo(@"Player URL: %@", contentURL);
				self.player = [AVPlayer playerWithURL:contentURL];
				self.playerView.player = self.player;
				// The player observes its "currentItem.status" keyPath, see callback in `observeValueForKeyPath:ofObject:change:context:`
			}
			else
			{
				[self fireEvent:self.resetEvent userInfo:ErrorUserInfo(error, @"The RTSMediaPlayerControllerDataSource implementation returned a nil contentURL and a nil error.")];
			}
		}];
	}];
	
	[loadSuccess setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		[self registerPeriodicTimeObserver];
	}];
	
	[reset setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		NSDictionary *errorUserInfo = transition.userInfo;
		if (errorUserInfo)
		{
			DDLogError(@"Playback did fail: %@", errorUserInfo[RTSMediaPlayerPlaybackDidFailErrorUserInfoKey]);
			[self postNotificationName:RTSMediaPlayerPlaybackDidFailNotification userInfo:errorUserInfo];
		}
		self.playerView.player = nil;
	}];
	
	self.idleState = idle;
	self.readyState = ready;
	self.playingState = playing;
	self.stalledState = stalled;
	
	self.loadEvent = load;
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
	{
		DDLogWarn(@"Invalid Transition: %@", error.localizedFailureReason);
	}
}

#pragma mark - Notifications

- (void) postNotificationName:(NSString *)notificationName userInfo:(NSDictionary *)userInfo
{
	NSNotification *notification = [NSNotification notificationWithName:notificationName object:self userInfo:userInfo];
	if ([NSThread isMainThread])
		[[NSNotificationCenter defaultCenter] postNotification:notification];
	else
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:NO];
}

#pragma mark - Playback

- (void) prepareToPlay
{
	[self fireEvent:self.loadEvent userInfo:nil];
}

- (void) playIdentifier:(NSString *)identifier
{
	if (![self.identifier isEqualToString:identifier])
	{
		[self reset];
		self.identifier = identifier;
	}
	
	[self.player play];
}

- (void) reset
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(prepareToPlay) object:nil];
	if (![self.stateMachine.currentState isEqual:self.idleState])
	{
		[self fireEvent:self.resetEvent userInfo:nil];
	}
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
		if ([_player isProxy])
		{
			[self performSelector:@selector(prepareToPlay) withObject:nil afterDelay:0];
		}
		return _player;
	}
}

- (void) setPlayer:(AVPlayer *)player
{
	@synchronized(self)
	{
		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
		if ([_player isProxy])
		{
			for (NSInvocation *invocation in ((RTSInvocationRecorder *)_player).invocations)
			{
				[invocation invokeWithTarget:player];
			}
		}
		else
		{
			[_player removeObserver:self forKeyPath:@"currentItem.status" context:(void *)AVPlayerItemStatusContext];
			[defaultCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
			[defaultCenter removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:_player.currentItem];
			[defaultCenter removeObserver:self name:AVPlayerItemTimeJumpedNotification object:_player.currentItem];
			[defaultCenter removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:_player.currentItem];
			[defaultCenter removeObserver:self name:AVPlayerItemNewAccessLogEntryNotification object:_player.currentItem];
			[defaultCenter removeObserver:self name:AVPlayerItemNewErrorLogEntryNotification object:_player.currentItem];
			[_player removeTimeObserver:self.periodicTimeObserver];
		}
		
		_player = player;
		
		AVPlayerItem *playerItem;
		if ([player isProxy] || !(playerItem = player.currentItem))
			return;
		
		[player addObserver:self forKeyPath:@"currentItem.status" options:0 context:(void *)AVPlayerItemStatusContext];
		[defaultCenter addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
		[defaultCenter addObserver:self selector:@selector(playerItemFailedToPlayToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
		[defaultCenter addObserver:self selector:@selector(playerItemTimeJumped:) name:AVPlayerItemTimeJumpedNotification object:playerItem];
		[defaultCenter addObserver:self selector:@selector(playerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:playerItem];
		[defaultCenter addObserver:self selector:@selector(playerItemNewAccessLogEntry:) name:AVPlayerItemNewAccessLogEntryNotification object:playerItem];
		[defaultCenter addObserver:self selector:@selector(playerItemNewErrorLogEntry:) name:AVPlayerItemNewErrorLogEntryNotification object:playerItem];
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
		AVPlayer *player = object;
		AVPlayerItem *playerItem = player.currentItem;
		switch (playerItem.status)
		{
			case AVPlayerItemStatusReadyToPlay:
				[self fireEvent:self.loadSuccessEvent userInfo:nil];
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
	[self fireEvent:self.endEvent userInfo:nil];
}

- (void) playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
	NSError *error = notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
	[self fireEvent:self.resetEvent userInfo:ErrorUserInfo(error, @"AVPlayerItemFailedToPlayToEndTimeNotification did not provide an error.")];
}

- (void) playerItemTimeJumped:(NSNotification *)notification
{
	DDLogDebug(@"%@ %@", THIS_METHOD, notification.userInfo);
}

- (void) playerItemPlaybackStalled:(NSNotification *)notification
{
	DDLogDebug(@"%@ %@", THIS_METHOD, notification.userInfo);
}

static void LogProperties(id object)
{
	unsigned int count;
	objc_property_t *properties = class_copyPropertyList([object class], &count);
	for (unsigned int i = 0; i < count; i++)
	{
		NSString *propertyName = @(property_getName(properties[i]));
		DDLogVerbose(@"    %@: %@", propertyName, [object valueForKey:propertyName]);
	}
	free(properties);
}

- (void) playerItemNewAccessLogEntry:(NSNotification *)notification
{
	DDLogDebug(@"%@ %@", THIS_METHOD, notification.userInfo);
	AVPlayerItem *playerItem = notification.object;
	LogProperties(playerItem.accessLog.events.lastObject);
}

- (void) playerItemNewErrorLogEntry:(NSNotification *)notification
{
	DDLogDebug(@"%@ %@", THIS_METHOD, notification.userInfo);
	AVPlayerItem *playerItem = notification.object;
	LogProperties(playerItem.errorLog.events.lastObject);
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
