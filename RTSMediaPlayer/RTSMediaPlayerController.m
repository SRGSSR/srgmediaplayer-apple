//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <objc/runtime.h>
#import <TransitionKit/TransitionKit.h>
#import <libextobjc/EXTScope.h>

#import "RTSMediaPlayerController.h"

#import "RTSMediaPlayerError.h"
#import "RTSMediaPlayerView.h"
#import "RTSPlaybackTimeObserver.h"
#import "RTSActivityGestureRecognizer.h"
#import "RTSMediaPlayerLogger.h"

NSTimeInterval const RTSMediaPlayerOverlayHidingDelay = 5.0;

NSString * const RTSMediaPlayerErrorDomain = @"RTSMediaPlayerErrorDomain";

NSString * const RTSMediaPlayerPlaybackStateDidChangeNotification = @"RTSMediaPlayerPlaybackStateDidChange";
NSString * const RTSMediaPlayerPlaybackDidFailNotification = @"RTSMediaPlayerPlaybackDidFail";

NSString * const RTSMediaPlayerWillShowControlOverlaysNotification = @"RTSMediaPlayerWillShowControlOverlays";
NSString * const RTSMediaPlayerDidShowControlOverlaysNotification = @"RTSMediaPlayerDidShowControlOverlays";
NSString * const RTSMediaPlayerWillHideControlOverlaysNotification = @"RTSMediaPlayerWillHideControlOverlays";
NSString * const RTSMediaPlayerDidHideControlOverlaysNotification = @"RTSMediaPlayerDidHideControlOverlays";


NSString * const RTSMediaPlayerPlaybackDidFailErrorUserInfoKey = @"Error";

NSString * const RTSMediaPlayerPreviousPlaybackStateUserInfoKey = @"PreviousPlaybackState";

NSString * const RTSMediaPlayerStateMachineContentURLInfoKey = @"ContentURL";
NSString * const RTSMediaPlayerStateMachineAutoPlayInfoKey = @"AutoPlay";
NSString * const RTSMediaPlayerPlaybackSeekingUponBlockingReasonInfoKey = @"BlockingReason";

@interface RTSMediaPlayerController () <RTSMediaPlayerControllerDataSource, UIGestureRecognizerDelegate>

@property (readonly) TKStateMachine *stateMachine;

@property (readwrite) TKState *idleState;
@property (readwrite) TKState *readyState;
@property (readwrite) TKState *pausedState;
@property (readwrite) TKState *playingState;
@property (readwrite) TKState *seekingState;
@property (readwrite) TKState *stalledState;

@property (readwrite) TKEvent *loadEvent;
@property (readwrite) TKEvent *loadSuccessEvent;
@property (readwrite) TKEvent *playEvent;
@property (readwrite) TKEvent *pauseEvent;
@property (readwrite) TKEvent *seekEvent;
@property (readwrite) TKEvent *endEvent;
@property (readwrite) TKEvent *stopEvent;
@property (readwrite) TKEvent *stallEvent;
@property (readwrite) TKEvent *resetEvent;

@property (readwrite) RTSMediaPlaybackState playbackState;
@property (readwrite) AVPlayer *player;
@property (readwrite) id periodicTimeObserver;
@property (readwrite) id playbackStartObserver;
@property (readwrite) CMTime previousPlaybackTime;

@property (readwrite) NSMutableDictionary *playbackTimeObservers;

@property (readonly) RTSMediaPlayerView *playerView;
@property (readonly) RTSActivityGestureRecognizer *activityGestureRecognizer;

@property (readonly) dispatch_source_t idleTimer;

@end

@implementation RTSMediaPlayerController

@synthesize player = _player;
@synthesize view = _view;
@synthesize overlayViews = _overlayViews;
@synthesize activityGestureRecognizer = _activityGestureRecognizer;
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
	
	self.overlayViewsHidingDelay = RTSMediaPlayerOverlayHidingDelay;
	self.playbackTimeObservers = [NSMutableDictionary dictionary];
	
	[self.stateMachine activate];
	
	return self;
}

- (void) dealloc
{
	if (![self.stateMachine.currentState isEqual:self.idleState])
	{
		RTSMediaPlayerLogWarning(@"The media player controller reached dealloc while still active. You should call the `reset` method before reaching dealloc.");
	}
	
	[self.activityView removeGestureRecognizer:self.activityGestureRecognizer];
	
	self.playerView.player = nil;
	self.player = nil;
}

#pragma mark - RTSMediaPlayerControllerDataSource 

// Used when initialized with `initWithContentURL:`
- (void)mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
	  contentURLForIdentifier:(NSString *)identifier
			completionHandler:(void (^)(NSURL *contentURL, NSError *error))completionHandler
{
	if (!identifier) {
		@throw [NSException exceptionWithName:NSInternalInconsistencyException
									   reason:@"Trying to play a media with a nil identifier."
									 userInfo:nil];
	}
	
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
	
	[[NSNotificationCenter defaultCenter] addObserverForName:TKStateMachineDidChangeStateNotification
													  object:stateMachine
													   queue:[NSOperationQueue new]
												  usingBlock:^(NSNotification *notification) {
													  TKTransition *transition = notification.userInfo[TKStateMachineDidChangeStateTransitionUserInfoKey];
													  RTSMediaPlayerLogDebug(@"(%@) ---[%@]---> (%@)",
																 transition.sourceState.name,
																 transition.event.name.lowercaseString,
																 transition.destinationState.name);
	}];
	
	TKState *idle = [TKState stateWithName:@"Idle"];
	TKState *preparing = [TKState stateWithName:@"Preparing"];
	TKState *ready = [TKState stateWithName:@"Ready"];
	TKState *playing = [TKState stateWithName:@"Playing"];
	TKState *seeking = [TKState stateWithName:@"Seeking"];
	TKState *paused = [TKState stateWithName:@"Paused"];
	TKState *stalled = [TKState stateWithName:@"Stalled"];
	TKState *ended = [TKState stateWithName:@"Ended"];
	[stateMachine addStates:@[ idle, preparing, ready, playing, seeking, paused, stalled, ended ]];
	stateMachine.initialState = idle;
	
	TKEvent *load = [TKEvent eventWithName:@"Load" transitioningFromStates:@[ idle ] toState:preparing];
	TKEvent *loadSuccess = [TKEvent eventWithName:@"Load Success" transitioningFromStates:@[ preparing ] toState:ready];
	TKEvent *play = [TKEvent eventWithName:@"Play" transitioningFromStates:@[ ready, paused, stalled, ended, seeking ] toState:playing];
	TKEvent *seek = [TKEvent eventWithName:@"Seek" transitioningFromStates:@[ ready, paused, stalled, ended, playing ] toState:seeking]; // Including 'Stalled"?
	TKEvent *pause = [TKEvent eventWithName:@"Pause" transitioningFromStates:@[ ready, playing, seeking ] toState:paused];
	TKEvent *end = [TKEvent eventWithName:@"End" transitioningFromStates:@[ playing ] toState:ended];
	TKEvent *stall = [TKEvent eventWithName:@"Stall" transitioningFromStates:@[ playing ] toState:stalled];
	NSMutableSet *allStatesButIdle = [NSMutableSet setWithSet:stateMachine.states];
	[allStatesButIdle removeObject:idle];
	TKEvent *reset = [TKEvent eventWithName:@"Reset" transitioningFromStates:[allStatesButIdle allObjects] toState:idle];
	
	[stateMachine addEvents:@[ load, loadSuccess, play, seek, pause, end, stall, reset ]];
	
	NSDictionary *states = @{ idle.name:      @(RTSMediaPlaybackStateIdle),
	                          preparing.name: @(RTSMediaPlaybackStatePreparing),
	                          ready.name:     @(RTSMediaPlaybackStateReady),
	                          playing.name:   @(RTSMediaPlaybackStatePlaying),
							  seeking.name:   @(RTSMediaPlaybackStateSeeking),
	                          paused.name:    @(RTSMediaPlaybackStatePaused),
	                          stalled.name:   @(RTSMediaPlaybackStateStalled),
	                          ended.name:     @(RTSMediaPlaybackStateEnded) };
	
	NSCAssert(states.allKeys.count == stateMachine.states.count, @"Must handle all states");
	
	@weakify(self)
	
	[[NSNotificationCenter defaultCenter] addObserverForName:TKStateMachineDidChangeStateNotification
													  object:stateMachine
													   queue:[NSOperationQueue mainQueue]
												  usingBlock:^(NSNotification *notification) {
													  @strongify(self)
													  TKTransition *transition = notification.userInfo[TKStateMachineDidChangeStateTransitionUserInfoKey];
													  self.playbackState = [states[transition.destinationState.name] integerValue];
												  }];
	
	[preparing setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
        if (!self.dataSource) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException
										   reason:@"RTSMediaPlayerController dataSource can not be nil."
										 userInfo:nil];
        }
		
		[self.dataSource mediaPlayerController:self contentURLForIdentifier:self.identifier completionHandler:^(NSURL *contentURL, NSError *error) {
			if (contentURL)
			{
				BOOL autoPlay = [transition.userInfo[RTSMediaPlayerStateMachineAutoPlayInfoKey] boolValue];
				[self fireEvent:self.loadSuccessEvent userInfo: @{ RTSMediaPlayerStateMachineContentURLInfoKey : contentURL, RTSMediaPlayerStateMachineAutoPlayInfoKey : @(autoPlay)}];
			}
			else
			{
				[self fireEvent:self.resetEvent userInfo:ErrorUserInfo(error, @"The RTSMediaPlayerControllerDataSource implementation returned a nil contentURL and a nil error.")];
			}
		}];
	}];
	
	[ready setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		
		NSURL *contentURL = transition.userInfo[RTSMediaPlayerStateMachineContentURLInfoKey];
		RTSMediaPlayerLogInfo(@"Player URL: %@", contentURL);
		
		// The player observes its "currentItem.status" keyPath, see callback in `observeValueForKeyPath:ofObject:change:context:`
		self.player = [AVPlayer playerWithURL:contentURL];
		self.playerView.player = self.player;
	}];
	
	[ready setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		
		BOOL autoPlay = [transition.userInfo[RTSMediaPlayerStateMachineAutoPlayInfoKey] boolValue];
		if (autoPlay) {
			[self.player play];
		}
		else if (self.player.rate == 0) {
			[self fireEvent:self.pauseEvent userInfo:nil];
		}
	}];
	
	[playing setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		[self resetIdleTimer];
	}];
	
	[playing setWillExitStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		[self registerPlaybackStartObserver];
	}];
		
	[reset setWillFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		NSDictionary *errorUserInfo = transition.userInfo;
		if (errorUserInfo) {
			RTSMediaPlayerLogError(@"Playback did fail: %@", errorUserInfo[RTSMediaPlayerPlaybackDidFailErrorUserInfoKey]);
			[self postNotificationName:RTSMediaPlayerPlaybackDidFailNotification userInfo:errorUserInfo];
		}
	}];
	
	[reset setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
		@strongify(self)
		self.previousPlaybackTime = kCMTimeInvalid;
		self.playerView.player = nil;
		self.player = nil;
	}];
	
	self.idleState = idle;
	self.readyState = ready;
	self.pausedState = paused;
	self.playingState = playing;
	self.stalledState = stalled;
	self.seekingState = seeking;
	
	self.loadEvent = load;
	self.loadSuccessEvent = loadSuccess;
	self.playEvent = play;
	self.pauseEvent = pause;
	self.endEvent = end;
	self.stallEvent = stall;
	self.seekEvent = seek;
	self.resetEvent = reset;
	
	_stateMachine = stateMachine;
	
	return _stateMachine;
}

- (void)fireEvent:(TKEvent *)event userInfo:(NSDictionary *)userInfo
{
	NSError *error;
	BOOL success = [self.stateMachine fireEvent:event userInfo:userInfo error:&error];
	if (!success) {
		RTSMediaPlayerLogWarning(@"Invalid Transition: %@", error.localizedFailureReason);
	}
}

#pragma mark - Notifications

- (void) postNotificationName:(NSString *)notificationName userInfo:(NSDictionary *)userInfo
{
	NSNotification *notification = [NSNotification notificationWithName:notificationName object:self userInfo:userInfo];
    if ([NSThread isMainThread]) {
		[[NSNotificationCenter defaultCenter] postNotification:notification];
    }
    else {
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:NO];
    }
}

#pragma mark - Playback

- (void) loadPlayerShouldPlayImediately:(BOOL)autoPlay
{
	if ([self.stateMachine.currentState isEqual:self.idleState]) {
		[self fireEvent:self.loadEvent userInfo: @{ RTSMediaPlayerStateMachineAutoPlayInfoKey : @(autoPlay) }];
	}
}

- (void) prepareToPlay
{
	[self loadPlayerShouldPlayImediately:NO];
}

- (void) play
{
	if ([self.stateMachine.currentState isEqual:self.idleState]) {
		[self loadPlayerShouldPlayImediately:YES];
	}
	else {
		[self.player play];
	}
}

- (void)playIdentifier:(NSString *)identifier
{
	if (![self.identifier isEqualToString:identifier]) {
		[self reset];
		self.identifier = identifier;
	}
	
	[self play];
}

- (void) pause
{
	[self fireEvent:self.pauseEvent userInfo:nil];
	[self.player pause];
}

- (void)mute:(BOOL)flag
{
	self.player.muted = flag;
}

- (BOOL)isMuted
{
	return self.player.muted;
}

- (void)reset
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(prepareToPlay) object:nil];
	if (![self.stateMachine.currentState isEqual:self.idleState]) {
		[self fireEvent:self.resetEvent userInfo:nil];
	}
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler
{
	if (self.stateMachine.currentState != self.seekingState) {
		[self fireEvent:self.seekEvent userInfo:nil];
	}
	
	RTSMediaPlayerLogInfo(@"Seeking to %@ sec.", @(CMTimeGetSeconds(time)));
	
	[self.player seekToTime:time
			toleranceBefore:kCMTimeZero
			 toleranceAfter:kCMTimeZero
		  completionHandler:completionHandler];
}

- (void)playAtTime:(CMTime)time
{
	[self seekToTime:time completionHandler:^(BOOL finished) {
		if (finished) {
			[self play];
		}
   }];
}

- (AVPlayerItem *)playerItem
{
	return self.player.currentItem;
}

- (RTSMediaPlaybackState) playbackState
{
	@synchronized(self) {
		return _playbackState;
	}
}

- (void) setPlaybackState:(RTSMediaPlaybackState)playbackState
{
	@synchronized(self) {
		if (_playbackState == playbackState) {
			return;
		}
		
		NSDictionary *userInfo = @{ RTSMediaPlayerPreviousPlaybackStateUserInfoKey: @(_playbackState) };
		
		_playbackState = playbackState;
		
		[self postNotificationName:RTSMediaPlayerPlaybackStateDidChangeNotification userInfo:userInfo];
	}
}

- (id) addPlaybackTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block
{
	if (!block)
	{
		return nil;
	}
	
	NSString *identifier = [[NSUUID UUID] UUIDString];
	RTSPlaybackTimeObserver *playbackTimeObserver = [self playbackTimeObserverForInterval:interval queue:queue];
	[playbackTimeObserver setBlock:block forIdentifier:identifier];
	
	if (self.player) {
		[playbackTimeObserver attachToMediaPlayer:self.player];
	}
	
	// Return the opaque identifier
	return identifier;
}

- (void) removePlaybackTimeObserver:(id)observer
{
	for (RTSPlaybackTimeObserver *playbackTimeObserver in [self.playbackTimeObservers allValues]) {
		[playbackTimeObserver removeBlockWithIdentifier:observer];
	}
}

- (RTSPlaybackTimeObserver *) playbackTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue
{
	NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@-%p", @(interval.value), @(interval.timescale), @(interval.flags), @(interval.epoch), queue];
	RTSPlaybackTimeObserver *playbackTimeObserver = self.playbackTimeObservers[key];
	if (!playbackTimeObserver)
	{
		playbackTimeObserver = [[RTSPlaybackTimeObserver alloc] initWithInterval:interval queue:queue];
		self.playbackTimeObservers[key] = playbackTimeObserver;
	}
	return playbackTimeObserver;
}

#pragma mark - AVPlayer

static const void * const AVPlayerItemStatusContext = &AVPlayerItemStatusContext;
static const void * const AVPlayerRateContext = &AVPlayerRateContext;

static const void * const AVPlayerItemPlaybackLikelyToKeepUpContext = &AVPlayerItemPlaybackLikelyToKeepUpContext;
static const void * const AVPlayerItemLoadedTimeRangesContext = &AVPlayerItemLoadedTimeRangesContext;

- (AVPlayer *) player
{
	@synchronized(self)
	{
		if ([self.stateMachine.currentState isEqual:self.idleState] && !_player) {
			RTSMediaPlayerLogWarning(@"Media player controller is not ready");
		}
		return _player;
	}
}

- (void) setPlayer:(AVPlayer *)player
{
	@synchronized(self)
	{
		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
		
		[_player removeObserver:self forKeyPath:@"currentItem.status" context:(void *)AVPlayerItemStatusContext];
		[_player removeObserver:self forKeyPath:@"rate" context:(void *)AVPlayerRateContext];
		[_player removeObserver:self forKeyPath:@"currentItem.playbackLikelyToKeepUp" context:(void *)AVPlayerItemPlaybackLikelyToKeepUpContext];
		[_player removeObserver:self forKeyPath:@"currentItem.loadedTimeRanges" context:(void *)AVPlayerItemLoadedTimeRangesContext];
		
		[defaultCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
		[defaultCenter removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:_player.currentItem];
		[defaultCenter removeObserver:self name:AVPlayerItemTimeJumpedNotification object:_player.currentItem];
		[defaultCenter removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:_player.currentItem];
		[defaultCenter removeObserver:self name:AVPlayerItemNewAccessLogEntryNotification object:_player.currentItem];
		[defaultCenter removeObserver:self name:AVPlayerItemNewErrorLogEntryNotification object:_player.currentItem];
		
		if (self.playbackStartObserver)
		{
			[_player removeTimeObserver:self.playbackStartObserver];
			self.playbackStartObserver = nil;
		}
		
		if (self.periodicTimeObserver)
		{
			[_player removeTimeObserver:self.periodicTimeObserver];
			self.periodicTimeObserver = nil;
		}
		
		[self unregisterPlaybackObservers];
		
		_player = player;
		
		AVPlayerItem *playerItem = player.currentItem;
		if (playerItem) {
			[player addObserver:self forKeyPath:@"currentItem.status" options:0 context:(void *)AVPlayerItemStatusContext];
			[player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:(void *)AVPlayerRateContext];
			[player addObserver:self forKeyPath:@"currentItem.playbackLikelyToKeepUp" options:0 context:(void *)AVPlayerItemPlaybackLikelyToKeepUpContext];
			[player addObserver:self forKeyPath:@"currentItem.loadedTimeRanges" options:NSKeyValueObservingOptionNew context:(void *)AVPlayerItemLoadedTimeRangesContext];

			[defaultCenter addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
			[defaultCenter addObserver:self selector:@selector(playerItemFailedToPlayToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
			[defaultCenter addObserver:self selector:@selector(playerItemTimeJumped:) name:AVPlayerItemTimeJumpedNotification object:playerItem];
			[defaultCenter addObserver:self selector:@selector(playerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:playerItem];
			[defaultCenter addObserver:self selector:@selector(playerItemNewAccessLogEntry:) name:AVPlayerItemNewAccessLogEntryNotification object:playerItem];
			[defaultCenter addObserver:self selector:@selector(playerItemNewErrorLogEntry:) name:AVPlayerItemNewErrorLogEntryNotification object:playerItem];
			
			[self registerPlaybackStartObserver];
			[self registerPeriodicTimeObserver];
			[self registerPlaybackObservers];
		}
	}
}

- (void)registerPlaybackStartObserver
{
	if (self.playbackStartObserver)
	{
		[self.player removeTimeObserver:self.playbackStartObserver];
		self.playbackStartObserver = nil;
	}
	
	CMTime currentTime = self.player.currentItem.currentTime;
	CMTime timeToAdd   = CMTimeMake(1, 10);
	CMTime resultTime  = CMTimeAdd(currentTime,timeToAdd);

	@weakify(self)
	self.playbackStartObserver = [self.player addBoundaryTimeObserverForTimes:@[[NSValue valueWithCMTime:resultTime]] queue:NULL usingBlock:^{
		@strongify(self)
		if (![self.stateMachine.currentState isEqual:self.playingState]) {
			[self fireEvent:self.playEvent userInfo:nil];
		}
		[self.player removeTimeObserver:self.playbackStartObserver];
		self.playbackStartObserver = nil;
	}];
}

- (void)registerPeriodicTimeObserver
{
	if (self.periodicTimeObserver)
	{
		[self.player removeTimeObserver:self.periodicTimeObserver];
		self.periodicTimeObserver = nil;
	}
	
	@weakify(self)
	self.periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime playbackTime) {
		@strongify(self)
		
		if (self.player.rate == 0)
			return;
		
		if (!CMTIME_IS_VALID(self.previousPlaybackTime))
			return;
		
		if(CMTimeGetSeconds(self.previousPlaybackTime) > CMTimeGetSeconds(playbackTime))
		{
			if (![self.stateMachine.currentState isEqual:self.playingState]) {
				[self fireEvent:self.playEvent userInfo:nil];
			}
		}

		self.previousPlaybackTime = playbackTime;
	}];
}

- (void) registerPlaybackObservers
{
	[self unregisterPlaybackObservers];
	
	for (RTSPlaybackTimeObserver *playbackBlockRegistration in [self.playbackTimeObservers allValues])
	{
		[playbackBlockRegistration attachToMediaPlayer:self.player];
	}
}

- (void) unregisterPlaybackObservers
{
	for (RTSPlaybackTimeObserver *playbackBlockRegistration in [self.playbackTimeObservers allValues])
	{
		[playbackBlockRegistration detach];
	}
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
				if (self.player.rate != 0 && ![self.stateMachine.currentState isEqual:self.readyState] && ![self.stateMachine.currentState isEqual:self.seekingState]) {
					[self play];
				}
				break;
			case AVPlayerItemStatusFailed:
				[self fireEvent:self.resetEvent userInfo:ErrorUserInfo(playerItem.error, @"The AVPlayerItem did report a failed status without an error.")];
				break;
			case AVPlayerItemStatusUnknown:
				break;
		}
	}
	else if (context == AVPlayerItemLoadedTimeRangesContext){
	
		NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
		if (timeRanges.count == 0)
			return;
		
		Float64 bufferMinDuration = 5.0f;
		
		CMTimeRange timerange = [timeRanges[0] CMTimeRangeValue];
		if(CMTimeGetSeconds(timerange.duration) >= bufferMinDuration && self.player.rate == 0) {
			[self.player prerollAtRate:0.0 completionHandler:^(BOOL finished) {
				if (![self.stateMachine.currentState isEqual:self.pausedState] && ![self.stateMachine.currentState isEqual:self.seekingState]) {
					[self play];
				}
			}];
		}
		
	}
	else if (context == AVPlayerRateContext)
	{
		float oldRate = [change[NSKeyValueChangeOldKey] floatValue];
		float newRate = [change[NSKeyValueChangeNewKey] floatValue];
		
		if (oldRate == newRate)
			return;
		
		AVPlayer *player = object;
		AVPlayerItem *playerItem = player.currentItem;
		
		if (playerItem.loadedTimeRanges.count == 0)
			return;
		
		CMTimeRange timerange = [playerItem.loadedTimeRanges[0] CMTimeRangeValue];
		BOOL stoppedManually = CMTimeGetSeconds(timerange.duration) > 0;
		
		if (oldRate == 1 && newRate == 0 && stoppedManually) {
			[self fireEvent:self.pauseEvent userInfo:nil];
		}
	}
	else if (context == AVPlayerItemPlaybackLikelyToKeepUpContext)
	{
		AVPlayer *player = object;
		if (!player.currentItem.playbackLikelyToKeepUp)
			return;
		
		if (![self.stateMachine.currentState isEqual:self.playingState]) {
			[self registerPlaybackStartObserver];
		}
		
		if ([self.stateMachine.currentState isEqual:self.stalledState]) {
			[player play];
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
	RTSMediaPlayerLogDebug(@"playerItemTimeJumped: %@", notification.userInfo);
}

- (void) playerItemPlaybackStalled:(NSNotification *)notification
{
	RTSMediaPlayerLogDebug(@"playerItemPlaybackStalled: %@", notification.userInfo);
}

static void LogProperties(id object)
{
	unsigned int count;
	objc_property_t *properties = class_copyPropertyList([object class], &count);
	for (unsigned int i = 0; i < count; i++)
	{
		NSString *propertyName = @(property_getName(properties[i]));
		RTSMediaPlayerLogTrace(@"    %@: %@", propertyName, [object valueForKey:propertyName]);
	}
	free(properties);
}

- (void) playerItemNewAccessLogEntry:(NSNotification *)notification
{
	RTSMediaPlayerLogVerbose(@"playerItemNewAccessLogEntry: %@", notification.userInfo);
	AVPlayerItem *playerItem = notification.object;
	LogProperties(playerItem.accessLog.events.lastObject);
}

- (void) playerItemNewErrorLogEntry:(NSNotification *)notification
{
	RTSMediaPlayerLogVerbose(@"playerItemNewErrorLogEntry: %@", notification.userInfo);
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
		
		UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
		doubleTapGestureRecognizer.numberOfTapsRequired = 2;
		[_view addGestureRecognizer:doubleTapGestureRecognizer];
		
		UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
		[singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
		[_view addGestureRecognizer:singleTapGestureRecognizer];

		UIView *activityView = self.activityView ?: _view;
		[activityView addGestureRecognizer:self.activityGestureRecognizer];

	}
	return _view;
}

- (RTSActivityGestureRecognizer *) activityGestureRecognizer
{
	if (!_activityGestureRecognizer) {
		_activityGestureRecognizer = [[RTSActivityGestureRecognizer alloc] initWithTarget:self action:@selector(resetIdleTimer)];
		_activityGestureRecognizer.delegate = self;
	}
	
	return _activityGestureRecognizer;
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

- (NSArray *) overlayViews
{
	@synchronized(self)
	{
		if (!_overlayViews)
			_overlayViews = @[ [UIView new] ];
			
		return _overlayViews;
	}
}

- (void) setOverlayViews:(NSArray *)overlayViews
{
	@synchronized(self)
	{
		_overlayViews = overlayViews;
	}
}

- (void) handleSingleTap
{
	[self toggleOverlays];
}

- (void) setOverlaysVisible:(BOOL)visible
{
	[self postNotificationName:visible ? RTSMediaPlayerWillShowControlOverlaysNotification : RTSMediaPlayerWillHideControlOverlaysNotification userInfo:nil];
	for (UIView *overlayView in self.overlayViews) {
		overlayView.hidden = !visible;
	}
	[self postNotificationName:visible ? RTSMediaPlayerDidShowControlOverlaysNotification : RTSMediaPlayerDidHideControlOverlaysNotification userInfo:nil];
}

- (void) toggleOverlays
{
	UIView *firstOverlayView = [self.overlayViews firstObject];
	[self setOverlaysVisible:firstOverlayView.hidden];
}

- (dispatch_source_t)idleTimer
{
	if (!_idleTimer) {
		_idleTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
		@weakify(self)
		dispatch_source_set_event_handler(_idleTimer, ^{
			@strongify(self)
			if ([self.stateMachine.currentState isEqual:self.playingState])
				[self setOverlaysVisible:NO];
		});
		dispatch_resume(_idleTimer);
	}
	return _idleTimer;
}

- (void) resetIdleTimer
{
	int64_t delayInNanoseconds = ((self.overlayViewsHidingDelay > 0.0) ? self.overlayViewsHidingDelay : RTSMediaPlayerOverlayHidingDelay) * NSEC_PER_SEC;
	int64_t toleranceInNanoseconds = 0.1 * NSEC_PER_SEC;
	dispatch_source_set_timer(self.idleTimer, dispatch_time(DISPATCH_TIME_NOW, delayInNanoseconds), DISPATCH_TIME_FOREVER, toleranceInNanoseconds);
}

#pragma mark - Resize Aspect

- (void)handleDoubleTap
{
	if (!self.playerView.playerLayer.isReadyForDisplay) {
		return;
	}
	
	[self toggleAspect];
}

- (void)toggleAspect
{
	AVPlayerLayer *playerLayer = self.playerView.playerLayer;
	if ([playerLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
		playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	}
	else {
		playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
	}
}

@end
