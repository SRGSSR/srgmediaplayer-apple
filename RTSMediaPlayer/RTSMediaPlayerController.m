//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <objc/runtime.h>
#import <TransitionKit/TransitionKit.h>
#import <libextobjc/EXTScope.h>

#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerControllerDataSource.h"
#import "RTSMediaSegmentsController.h"

#import "RTSMediaPlayerError.h"
#import "RTSMediaPlayerView.h"
#import "RTSPeriodicTimeObserver.h"
#import "RTSActivityGestureRecognizer.h"
#import "RTSMediaPlayerLogger+Private.h"

static const void * const RTSMediaPlayerPictureInPicturePossibleContext = &RTSMediaPlayerPictureInPicturePossibleContext;
static const void * const RTSMediaPlayerPictureInPictureActiveContext = &RTSMediaPlayerPictureInPictureActiveContext;

NSTimeInterval const RTSMediaPlayerOverlayHidingDelay = 5.0;
NSTimeInterval const RTSMediaLiveDefaultTolerance = 30.0;		// same tolerance as built-in iOS player

NSString * const RTSMediaPlayerErrorDomain = @"RTSMediaPlayerErrorDomain";

NSString * const RTSMediaPlayerPlaybackStateDidChangeNotification = @"RTSMediaPlayerPlaybackStateDidChange";
NSString * const RTSMediaPlayerPlaybackDidFailNotification = @"RTSMediaPlayerPlaybackDidFail";

NSString * const RTSMediaPlayerPictureInPictureStateChangeNotification = @"RTSMediaPlayerPictureInPictureStateChangeNotification";

NSString * const RTSMediaPlayerWillShowControlOverlaysNotification = @"RTSMediaPlayerWillShowControlOverlays";
NSString * const RTSMediaPlayerDidShowControlOverlaysNotification = @"RTSMediaPlayerDidShowControlOverlays";
NSString * const RTSMediaPlayerWillHideControlOverlaysNotification = @"RTSMediaPlayerWillHideControlOverlays";
NSString * const RTSMediaPlayerDidHideControlOverlaysNotification = @"RTSMediaPlayerDidHideControlOverlays";

NSString * const RTSMediaPlayerPlaybackDidFailErrorUserInfoKey = @"Error";

NSString * const RTSMediaPlayerPreviousPlaybackStateUserInfoKey = @"PreviousPlaybackState";

NSString * const RTSMediaPlayerStateMachineContentURLInfoKey = @"ContentURL";
NSString * const RTSMediaPlayerPlaybackSeekingUponBlockingReasonInfoKey = @"BlockingReason";

@interface RTSMediaPlayerController () <RTSMediaPlayerControllerDataSource, UIGestureRecognizerDelegate>

@property (readwrite, copy) NSString *identifier;

@property (readonly) TKStateMachine *stateMachine;

@property (readwrite) TKState *idleState;
@property (readwrite) TKState *readyState;
@property (readwrite) TKState *pausedState;
@property (readwrite) TKState *playingState;
@property (readwrite) TKState *seekingState;
@property (readwrite) TKState *stalledState;
@property (readwrite) TKState *endedState;

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
@property (readwrite) NSValue *startTimeValue;

@property (readwrite) NSMutableDictionary *periodicTimeObservers;

@property (readonly) RTSMediaPlayerView *playerView;
@property (readonly) RTSActivityGestureRecognizer *activityGestureRecognizer;

@property (readwrite, weak) id stateTransitionObserver;

@property (readonly) dispatch_source_t idleTimer;

@property (nonatomic) AVPictureInPictureController *pictureInPictureController;

@property (nonatomic, weak) RTSMediaSegmentsController *segmentsController;

@property (nonatomic) id contentURLRequestHandle;

@property (nonatomic, assign) BOOL playScheduled;
@property (nonatomic, assign) BOOL pauseScheduled;

@end

@implementation RTSMediaPlayerController

@synthesize player = _player;
@synthesize view = _view;
@synthesize pictureInPictureController = _pictureInPictureController;
@synthesize overlayViews = _overlayViews;
@synthesize overlayViewsHidingDelay = _overlayViewsHidingDelay;
@synthesize activityGestureRecognizer = _activityGestureRecognizer;
@synthesize playbackState = _playbackState;
@synthesize stateMachine = _stateMachine;
@synthesize idleTimer = _idleTimer;
@synthesize identifier = _identifier;
@synthesize muted = _muted;

#pragma mark - Initialization

- (instancetype)init
{
	return [self initWithContentURL:[NSURL URLWithString:@""]];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL
{
	return [self initWithContentIdentifier:contentURL.absoluteString dataSource:self];
}

- (instancetype)initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	if (!(self = [super init])) {
		return nil;
	}
	
	_identifier = identifier;
	_dataSource = dataSource;
	_overlaysVisible = YES;		// The player always open with visible overlays
	
	self.overlayViewsHidingDelay = RTSMediaPlayerOverlayHidingDelay;
	self.periodicTimeObservers = [NSMutableDictionary dictionary];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillResignActive:)
												 name:UIApplicationWillResignActiveNotification
											   object:nil];
	
	[self.stateMachine activate];

	self.liveTolerance = RTSMediaLiveDefaultTolerance;
	
	return self;
}

- (void)dealloc
{
	[self reset];
		
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self.stateTransitionObserver];
	
	[_view removeFromSuperview];
	[_activityView removeGestureRecognizer:_activityGestureRecognizer];
	
	self.player = nil;
}

#pragma mark - RTSMediaPlayerControllerDataSource

// Used when initialized with `initWithContentURL:`
- (id)mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
	contentURLForIdentifier:(NSString *)identifier
		  completionHandler:(void (^)(NSString *identifier, NSURL *contentURL, NSError *error))completionHandler
{
	if (!identifier) {
		@throw [NSException exceptionWithName:NSInternalInconsistencyException
									   reason:@"Trying to play a media with a nil identifier."
									 userInfo:nil];
	}
	
	completionHandler(identifier, [NSURL URLWithString:identifier], nil);
	return nil;
}

- (void)cancelContentURLRequest:(id)request
{}

#pragma mark - Loading

static NSDictionary * ErrorUserInfo(NSError *error, NSString *failureReason)
{
	NSDictionary *userInfo = @{ NSLocalizedFailureReasonErrorKey: failureReason ?: @"Unknown failure reason.",
								NSLocalizedDescriptionKey: @"An unknown error occured." };
	NSError *unknownError = [NSError errorWithDomain:RTSMediaPlayerErrorDomain code:RTSMediaPlayerErrorUnknown userInfo:userInfo];
	return @{ RTSMediaPlayerPlaybackDidFailErrorUserInfoKey: error ?: unknownError };
}

- (TKStateMachine *)stateMachine
{
	if (_stateMachine) {
		return _stateMachine;
	}
	
	TKStateMachine *stateMachine = [TKStateMachine new];
	
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
	
	self.stateTransitionObserver = [[NSNotificationCenter defaultCenter] addObserverForName:TKStateMachineDidChangeStateNotification
																					 object:stateMachine
																					  queue:[NSOperationQueue mainQueue]
																				 usingBlock:^(NSNotification *notification) {
																					 @strongify(self)
																					 TKTransition *t = notification.userInfo[TKStateMachineDidChangeStateTransitionUserInfoKey];
																					 RTSMediaPlayerLogDebug(@"(%@) ---[%@]---> (%@)", t.sourceState.name, t.event.name.lowercaseString, t.destinationState.name);
																					 NSInteger newPlaybackState = [states[t.destinationState.name] integerValue];
																					 self.playbackState = newPlaybackState;
																				 }];
	
    [idle setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        @strongify(self)
        
        [self.dataSource cancelContentURLRequest:self.contentURLRequestHandle];
        self.contentURLRequestHandle = nil;
    }];
    
	[preparing setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		if (!self.dataSource) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException
										   reason:@"RTSMediaPlayerController dataSource can not be nil."
										 userInfo:nil];
		}
		
		self.contentURLRequestHandle = [self.dataSource mediaPlayerController:self contentURLForIdentifier:self.identifier completionHandler:^(NSString *identifier, NSURL *contentURL, NSError *error) {
            self.contentURLRequestHandle = nil;
            
            if (![identifier isEqualToString:self.identifier]) {
                return;
            }
            else if (contentURL) {
				[self fireEvent:self.loadSuccessEvent userInfo:@{ RTSMediaPlayerStateMachineContentURLInfoKey : contentURL }];
			}
			else {
				[self fireEvent:self.resetEvent
					   userInfo:ErrorUserInfo(error, @"The RTSMediaPlayerControllerDataSource implementation returned a nil contentURL and a nil error.")];
			}
		}];
	}];
	
	[ready setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		
		NSURL *contentURL = transition.userInfo[RTSMediaPlayerStateMachineContentURLInfoKey];
		RTSMediaPlayerLogInfo(@"Player URL: %@", contentURL);
		
		// The player observes its "currentItem.status" keyPath, see callback in `observeValueForKeyPath:ofObject:change:context:`
		self.player = [AVPlayer playerWithURL:contentURL];
		self.player.muted = _muted;
		
		self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
		self.player.allowsExternalPlayback = YES;
		self.player.usesExternalPlaybackWhileExternalScreenIsActive = YES;
		
		self.playerView.player = self.player;
	}];
	
	[ready setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		
		// Preparing to play, but starting paused
		if (self.player.rate == 0 && !self.startTimeValue) {
			// Ugly trick. We do not want to emit pause events before the player is ready to play, so we schedule the pause
			// to be sent when the player is really ready to play
			self.pauseScheduled = YES;
		}
	}];
	
	[playing setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		[self resetIdleTimer];
	}];
	
	[playing setWillExitStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		[self registerPlaybackStartBoundaryObserver];
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
		// Do not reset audio session right here, as it breaks cases where there are multiple players on the same
		// screen, all playing, but only one with sound (e.g. multi-lives).
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
	self.endedState = ended;
	
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

- (void)postNotificationName:(NSString *)notificationName userInfo:(NSDictionary *)userInfo
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

- (void)loadPlayerAndAutoStartAtTime:(NSValue *)startTimeValue
{
	if ([self.stateMachine.currentState isEqual:self.idleState]) {
		self.startTimeValue = startTimeValue;
		[self fireEvent:self.loadEvent userInfo:nil];
	}
}

- (void)prepareToPlay
{
	[self loadPlayerAndAutoStartAtTime:nil];
}

- (void)play
{
	if(!self.identifier) {
		return;
	}
	
	if ([self.stateMachine.currentState isEqual:self.endedState]) {
		[self reset];
	}
	
	if ([self.stateMachine.currentState isEqual:self.idleState]) {
		[self loadPlayerAndAutoStartAtTime:[NSValue valueWithCMTime:kCMTimeZero]];
	}
	else {
		[self.player play];
	}
}

- (void)prepareToPlayIdentifier:(NSString *)identifier
{
	if (![self.identifier isEqualToString:identifier]) {
		[self reset];
		self.identifier = identifier;
	}
	
	[self prepareToPlay];
}

- (void)playIdentifier:(NSString *)identifier
{
	if (![self.identifier isEqualToString:identifier]) {
		[self reset];
		self.identifier = identifier;
	}
	
	[self play];
}

- (void)playIdentifier:(NSString *)identifier atTime:(CMTime)time
{
	if ([self.identifier isEqualToString:identifier]) {
		[self playAtTime:time];
	}
	else {
		[self reset];
		self.identifier = identifier;
		[self loadPlayerAndAutoStartAtTime:[NSValue valueWithCMTime:time]];
	}
}

- (void)pause
{
	// The state machine state is updated to 'Paused' in the KVO implementation method
	[self.player pause];
}

- (void)setMuted:(BOOL)muted
{
	_muted = muted;
	
	self.player.muted = muted;
}

- (BOOL)isMuted
{
	return _muted;
}

- (void)reset
{
    // Reset the PIP controller so that it gets lazily attached again. This forces a new player layer relationship,
    // preventing black screen issues when playing another media identifier while already in picture in picture mode
    if (_pictureInPictureController) {
        [_pictureInPictureController removeObserver:self forKeyPath:@"pictureInPicturePossible" context:(void *)RTSMediaPlayerPictureInPicturePossibleContext];
        [_pictureInPictureController removeObserver:self forKeyPath:@"pictureInPictureActive" context:(void *)RTSMediaPlayerPictureInPictureActiveContext];
        _pictureInPictureController = nil;
    }
    
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(prepareToPlay) object:nil];
	if (![self.stateMachine.currentState isEqual:self.idleState]) {
		[self fireEvent:self.resetEvent userInfo:nil];
	}
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler
{
	if (CMTIME_IS_INVALID(time)) {
		return;
	}
	
	if (self.stateMachine.currentState != self.seekingState) {
		[self fireEvent:self.seekEvent userInfo:nil];
	}
	
	RTSMediaPlayerLogDebug(@"Seeking to %.2f sec.", CMTimeGetSeconds(time));
	
    [self.player seekToTime:time
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero
          completionHandler:completionHandler];
}

- (void)playAtTime:(CMTime)time
{
	[self playAtTime:time completionHandler:nil];
}

- (void)playAtTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;
{
	if ([self.stateMachine.currentState isEqual:self.idleState]) {
		[self loadPlayerAndAutoStartAtTime:[NSValue valueWithCMTime:time]];
	}
	else {
		[self seekToTime:time completionHandler:completionHandler];
	}
}

- (AVPlayerItem *)playerItem
{
	return self.player.currentItem;
}

- (RTSMediaPlaybackState)playbackState
{
	@synchronized(self) {
		return _playbackState;
	}
}

- (void)setPlaybackState:(RTSMediaPlaybackState)playbackState
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

#pragma mark - Specialized Accessors

- (CMTimeRange)timeRange
{
	AVPlayerItem *playerItem = self.playerItem;
	
	NSValue *firstSeekableTimeRangeValue = [playerItem.seekableTimeRanges firstObject];
	if (!firstSeekableTimeRangeValue) {
		return kCMTimeRangeInvalid;
	}
	
	NSValue *lastSeekableTimeRangeValue = [playerItem.seekableTimeRanges lastObject];
	if (!lastSeekableTimeRangeValue) {
		return kCMTimeRangeInvalid;
	}
	
	CMTimeRange firstSeekableTimeRange = [firstSeekableTimeRangeValue CMTimeRangeValue];
	CMTimeRange lastSeekableTimeRange = [lastSeekableTimeRangeValue CMTimeRangeValue];
	
	if (!CMTIMERANGE_IS_VALID(firstSeekableTimeRange) || !CMTIMERANGE_IS_VALID(lastSeekableTimeRange)) {
		return kCMTimeRangeInvalid;
	}
	
	CMTimeRange timeRange = CMTimeRangeFromTimeToTime(firstSeekableTimeRange.start, CMTimeRangeGetEnd(lastSeekableTimeRange));
    
    // DVR window size too small. Check that we the stream is not an on-demand one first, of course
	if (CMTIME_IS_INDEFINITE(self.playerItem.duration) && CMTimeGetSeconds(timeRange.duration) < self.minimumDVRWindowLength) {
        return CMTimeRangeMake(timeRange.start, kCMTimeZero);
    }
    else {
        return timeRange;
    }
}

- (RTSMediaType)mediaType
{
	if (! self.player) {
		return RTSMediaTypeUnknown;
	}
	
	NSArray *tracks = self.player.currentItem.tracks;
	if (tracks.count == 0) {
		return RTSMediaTypeUnknown;
	}
	
	NSString *mediaType = [[tracks.firstObject assetTrack] mediaType];
	return [mediaType isEqualToString:AVMediaTypeVideo] ? RTSMediaTypeVideo : RTSMediaTypeAudio;
}

- (RTSMediaStreamType)streamType
{
    CMTimeRange timeRange = self.timeRange;
    
	if (CMTIMERANGE_IS_INVALID(timeRange)) {
		return RTSMediaStreamTypeUnknown;
	}
	else if (CMTIMERANGE_IS_EMPTY(timeRange)) {
		return RTSMediaStreamTypeLive;
	}
	else if (CMTIME_IS_INDEFINITE(self.playerItem.duration)) {
		return RTSMediaStreamTypeDVR;
	}
	else {
		return RTSMediaStreamTypeOnDemand;
	}
}

- (void)setMinimumDVRWindowLength:(NSTimeInterval)minimumDVRWindowLength
{
    if (minimumDVRWindowLength < 0.) {
        RTSMediaPlayerLogWarning(@"The minimum DVR window length cannot be negative. Set to 0");
        _minimumDVRWindowLength = 0.;
    }
    else {
        _minimumDVRWindowLength = minimumDVRWindowLength;
    }
}

- (void)setLiveTolerance:(NSTimeInterval)liveTolerance
{
	if (liveTolerance < 0.) {
		RTSMediaPlayerLogWarning(@"Live tolerance cannot be negative. Set to 0");
		_liveTolerance = 0.;
	}
	else {
		_liveTolerance = liveTolerance;
	}
}

- (BOOL)isLive
{
	if (!self.playerItem) {
		return NO;
	}
	
	if (self.streamType == RTSMediaStreamTypeLive) {
		return YES;
	}
	else if (self.streamType == RTSMediaStreamTypeDVR) {
		return CMTimeGetSeconds(CMTimeSubtract(CMTimeRangeGetEnd(self.timeRange), self.playerItem.currentTime)) < self.liveTolerance;
	}
	else {
		return NO;
	}
}


#pragma mark - AVPlayer

static const void * const AVPlayerItemStatusContext = &AVPlayerItemStatusContext;
static const void * const AVPlayerRateContext = &AVPlayerRateContext;

static const void * const AVPlayerItemPlaybackLikelyToKeepUpContext = &AVPlayerItemPlaybackLikelyToKeepUpContext;
static const void * const AVPlayerItemLoadedTimeRangesContext = &AVPlayerItemLoadedTimeRangesContext;

static const void * const AVPlayerItemBufferEmptyContext = &AVPlayerItemBufferEmptyContext;

- (AVPlayer *)player
{
	@synchronized(self)
	{
		// Commented out for now (2015-07-28), as it triggers too many messages to be useful.
		//		if ([self.stateMachine.currentState isEqual:self.idleState] && !_player) {
		//			RTSMediaPlayerLogWarning(@"Media player controller is not ready");
		//		}
		return _player;
	}
}

- (void)setPlayer:(AVPlayer *)player
{
	@synchronized(self)
	{
		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
		
		[_player removeObserver:self forKeyPath:@"currentItem.status" context:(void *)AVPlayerItemStatusContext];
		[_player removeObserver:self forKeyPath:@"rate" context:(void *)AVPlayerRateContext];
		[_player removeObserver:self forKeyPath:@"currentItem.playbackLikelyToKeepUp" context:(void *)AVPlayerItemPlaybackLikelyToKeepUpContext];
		[_player removeObserver:self forKeyPath:@"currentItem.loadedTimeRanges" context:(void *)AVPlayerItemLoadedTimeRangesContext];
        [_player removeObserver:self forKeyPath:@"currentItem.playbackBufferEmpty" context:(void *)AVPlayerItemBufferEmptyContext];
		
		[defaultCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
		[defaultCenter removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:_player.currentItem];
		[defaultCenter removeObserver:self name:AVPlayerItemTimeJumpedNotification object:_player.currentItem];
		[defaultCenter removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:_player.currentItem];
		[defaultCenter removeObserver:self name:AVPlayerItemNewAccessLogEntryNotification object:_player.currentItem];
		[defaultCenter removeObserver:self name:AVPlayerItemNewErrorLogEntryNotification object:_player.currentItem];
		
		if (self.playbackStartObserver) {
			[_player removeTimeObserver:self.playbackStartObserver];
			self.playbackStartObserver = nil;
		}
		
		if (self.periodicTimeObserver) {
			[_player removeTimeObserver:self.periodicTimeObserver];
			self.periodicTimeObserver = nil;
		}
		
		[self unregisterCustomPeriodicTimeObservers];
		
		_player = player;
		
		AVPlayerItem *playerItem = player.currentItem;
		if (playerItem) {
			[player addObserver:self forKeyPath:@"currentItem.status" options:0 context:(void *)AVPlayerItemStatusContext];
			[player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:(void *)AVPlayerRateContext];
			[player addObserver:self forKeyPath:@"currentItem.playbackLikelyToKeepUp" options:0 context:(void *)AVPlayerItemPlaybackLikelyToKeepUpContext];
			[player addObserver:self forKeyPath:@"currentItem.loadedTimeRanges" options:NSKeyValueObservingOptionNew context:(void *)AVPlayerItemLoadedTimeRangesContext];
            [player addObserver:self forKeyPath:@"currentItem.playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:(void *)AVPlayerItemBufferEmptyContext];
			
			[defaultCenter addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
			[defaultCenter addObserver:self selector:@selector(playerItemFailedToPlayToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
			[defaultCenter addObserver:self selector:@selector(playerItemTimeJumped:) name:AVPlayerItemTimeJumpedNotification object:playerItem];
			[defaultCenter addObserver:self selector:@selector(playerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:playerItem];
			[defaultCenter addObserver:self selector:@selector(playerItemNewAccessLogEntry:) name:AVPlayerItemNewAccessLogEntryNotification object:playerItem];
			[defaultCenter addObserver:self selector:@selector(playerItemNewErrorLogEntry:) name:AVPlayerItemNewErrorLogEntryNotification object:playerItem];
			
			[self registerPlaybackStartBoundaryObserver];
			[self registerPlaybackRatePeriodicTimeObserver];
			[self registerCustomPeriodicTimeObservers];
		}
	}
}

- (void)registerPlaybackStartBoundaryObserver
{
	if (self.playbackStartObserver) {
		[self.player removeTimeObserver:self.playbackStartObserver];
		self.playbackStartObserver = nil;
	}
	
	CMTime currentTime = self.player.currentItem.currentTime;
	CMTime timeToAdd   = CMTimeMake(1, 10);
	CMTime resultTime  = CMTimeAdd(currentTime,timeToAdd);
	
	@weakify(self)
	self.playbackStartObserver = [self.player addBoundaryTimeObserverForTimes:@[[NSValue valueWithCMTime:resultTime]] queue:NULL usingBlock:^{
		@strongify(self)
		if (![self.stateMachine.currentState isEqual:self.playingState] && ![self.stateMachine.currentState isEqual:self.endedState]) {
			[self fireEvent:self.playEvent userInfo:nil];
		}
		[self.player removeTimeObserver:self.playbackStartObserver];
		self.playbackStartObserver = nil;
	}];
}

- (void)registerPlaybackRatePeriodicTimeObserver
{
	if (self.periodicTimeObserver) {
		[self.player removeTimeObserver:self.periodicTimeObserver];
		self.periodicTimeObserver = nil;
	}
	
	@weakify(self)
	self.periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime playbackTime) {
		@strongify(self)
		
		if (self.player.rate == 0) {
			return;
		}
		
		if ((self.player.rate == 1) && [self.stateMachine.currentState isEqual:self.pausedState]) {
			[self fireEvent:self.playEvent userInfo:nil];
		}
		
		if (CMTIME_IS_VALID(self.previousPlaybackTime) &&
			(CMTIME_COMPARE_INLINE(self.previousPlaybackTime, >, playbackTime)))
		{
			if (![self.stateMachine.currentState isEqual:self.playingState]) {
				[self fireEvent:self.playEvent userInfo:nil];
			}
		}
		
		self.previousPlaybackTime = playbackTime;
	}];
}


#pragma mark - Custom Periodic Observers

- (void)registerCustomPeriodicTimeObservers
{
	[self unregisterCustomPeriodicTimeObservers];
	
	for (RTSPeriodicTimeObserver *playbackBlockRegistration in [self.periodicTimeObservers allValues]) {
		[playbackBlockRegistration attachToMediaPlayer:self.player];
	}
}

- (void)unregisterCustomPeriodicTimeObservers
{
	for (RTSPeriodicTimeObserver *playbackBlockRegistration in [self.periodicTimeObservers allValues]) {
		[playbackBlockRegistration detachFromMediaPlayer];
	}
}

- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block
{
	if (!block) {
		return nil;
	}
	
	NSString *identifier = [[NSUUID UUID] UUIDString];
	RTSPeriodicTimeObserver *periodicTimeObserver = [self periodicTimeObserverForInterval:interval queue:queue];
	[periodicTimeObserver setBlock:block forIdentifier:identifier];
	
	if (self.player) {
		[periodicTimeObserver attachToMediaPlayer:self.player];
	}
	
	// Return the opaque identifier
	return identifier;
}

- (void)removePeriodicTimeObserver:(id)observer
{
	for (RTSPeriodicTimeObserver *periodicTimeObserver in [self.periodicTimeObservers allValues]) {
		[periodicTimeObserver removeBlockWithIdentifier:observer];
	}
}

- (RTSPeriodicTimeObserver *)periodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue
{
	NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@-%p", @(interval.value), @(interval.timescale), @(interval.flags), @(interval.epoch), queue];
	RTSPeriodicTimeObserver *periodicTimeObserver = self.periodicTimeObservers[key];
	
	if (!periodicTimeObserver) {
		periodicTimeObserver = [[RTSPeriodicTimeObserver alloc] initWithInterval:interval queue:queue];
		self.periodicTimeObservers[key] = periodicTimeObserver;
	}
	
	return periodicTimeObserver;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == AVPlayerItemStatusContext) {
		AVPlayer *player = object;
		AVPlayerItem *playerItem = player.currentItem;
		switch (playerItem.status) {
			case AVPlayerItemStatusReadyToPlay:
                if (self.playScheduled) {
                    self.playScheduled = NO;
                    [self fireEvent:self.playEvent userInfo:nil];
					[self play];
                }
				else if (![self.stateMachine.currentState isEqual:self.playingState] && self.startTimeValue) {
					if (CMTIME_COMPARE_INLINE([self.startTimeValue CMTimeValue], ==, kCMTimeZero) || CMTIME_IS_INVALID([self.startTimeValue CMTimeValue])) {
						[self play];
					}
					else {
						// Not using [self seek...] to avoid triggering undesirable state events.
						[self.player seekToTime:[self.startTimeValue CMTimeValue]
                                toleranceBefore:kCMTimeZero
                                 toleranceAfter:kCMTimeZero
							  completionHandler:^(BOOL finished) {
								  if (finished) {
									  [self play];
								  }
							  }];
					}
				}
                else if ([self.stateMachine.currentState isEqual:self.seekingState]) {
                    [self.player play];
                }
				break;
			case AVPlayerItemStatusFailed:
				[self fireEvent:self.resetEvent userInfo:ErrorUserInfo(playerItem.error, @"The AVPlayerItem did report a failed status without an error.")];
				break;
			case AVPlayerItemStatusUnknown:
				break;
		}
        self.startTimeValue = nil;
	}
	else if (context == AVPlayerItemLoadedTimeRangesContext) {
		NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
		if (timeRanges.count == 0) {
			return;
		}
		
		Float64 bufferMinDuration = 5.0f;
		
		CMTimeRange timerange = [timeRanges.firstObject CMTimeRangeValue]; // Yes, subscripting with [0] may lead to a crash??
		if (CMTimeGetSeconds(timerange.duration) >= bufferMinDuration && self.player.rate == 0) {
			[self.player prerollAtRate:0.0 completionHandler:^(BOOL finished) {
				if (self.pauseScheduled) {
					self.pauseScheduled = NO;
					[self fireEvent:self.pauseEvent userInfo:nil];
				}
				else if (![self.stateMachine.currentState isEqual:self.pausedState] &&
						 ![self.stateMachine.currentState isEqual:self.seekingState])
				{
					[self play];
				}
			}];
		}
	}
	else if (context == AVPlayerRateContext) {
		float oldRate = [change[NSKeyValueChangeOldKey] floatValue];
		float newRate = [change[NSKeyValueChangeNewKey] floatValue];
		
		if (oldRate == newRate) {
			return;
		}
		
		AVPlayer *player = object;
		AVPlayerItem *playerItem = player.currentItem;
		
		if (playerItem.loadedTimeRanges.count == 0) {
			return;
		}
		
		CMTimeRange timerange = [playerItem.loadedTimeRanges.firstObject CMTimeRangeValue]; // Yes, subscripting with [0] may lead to a crash??
		BOOL stoppedManually = CMTimeGetSeconds(timerange.duration) > 0;
		
		if (oldRate == 1 && newRate == 0 && stoppedManually) {
			[self fireEvent:self.pauseEvent userInfo:nil];
		}
		else if (newRate == 1 && oldRate == 0 && self.stateMachine.currentState != self.playingState) {
			// Ugly trick. We do not want to emit play events before the player is ready to play, so we schedule the play
			// to be sent when the player is really ready to play
            self.playScheduled = YES;
		}
	}
	else if (context == AVPlayerItemPlaybackLikelyToKeepUpContext) {
		AVPlayer *player = object;
		if (!player.currentItem.playbackLikelyToKeepUp) {
			return;
		}
		
		if (![self.stateMachine.currentState isEqual:self.playingState]) {
			[self registerPlaybackStartBoundaryObserver];
		}
		
		if ([self.stateMachine.currentState isEqual:self.stalledState]) {
			[player play];
		}
	}
    else if (context == AVPlayerItemBufferEmptyContext) {
        [self fireEvent:self.stallEvent userInfo:nil];
    }
	else if (context == RTSMediaPlayerPictureInPicturePossibleContext || context == RTSMediaPlayerPictureInPictureActiveContext) {
		[self postNotificationName:RTSMediaPlayerPictureInPictureStateChangeNotification userInfo:nil];
        
        // Always show overlays again when picture in picture is disabled
        if (context == RTSMediaPlayerPictureInPictureActiveContext && !self.pictureInPictureController.isPictureInPictureActive) {
            [self setOverlaysVisible:YES];
        }
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - Player Item Notifications

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
	RTSMediaPlayerLogVerbose(@"playerItemTimeJumped: %@", notification.userInfo);
}

- (void) playerItemPlaybackStalled:(NSNotification *)notification
{
	RTSMediaPlayerLogVerbose(@"playerItemPlaybackStalled: %@", notification.userInfo);
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

- (void)attachPlayerToView:(UIView *)containerView
{
	[self.view removeFromSuperview];
	self.view.frame = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds));
	[containerView insertSubview:self.view atIndex:0];
}

- (UIView *)view
{
    if (!_view) {
        RTSMediaPlayerView *mediaPlayerView = [RTSMediaPlayerView new];
        
        mediaPlayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        [mediaPlayerView addGestureRecognizer:doubleTapGestureRecognizer];
        
        UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
        [mediaPlayerView addGestureRecognizer:singleTapGestureRecognizer];
        
        UIView *activityView = self.activityView ?: mediaPlayerView;
        [activityView addGestureRecognizer:self.activityGestureRecognizer];
		
        _view = mediaPlayerView;
    }
    
    return _view;
}

- (AVPictureInPictureController *)pictureInPictureController
{
	if (!_pictureInPictureController) {
		_pictureInPictureController = [[AVPictureInPictureController alloc] initWithPlayerLayer:self.playerView.playerLayer];
		[_pictureInPictureController addObserver:self forKeyPath:@"pictureInPicturePossible" options:NSKeyValueObservingOptionNew context:(void *)RTSMediaPlayerPictureInPicturePossibleContext];
		[_pictureInPictureController addObserver:self forKeyPath:@"pictureInPictureActive" options:NSKeyValueObservingOptionNew context:(void *)RTSMediaPlayerPictureInPictureActiveContext];
	}
	return _pictureInPictureController;
}

- (RTSActivityGestureRecognizer *)activityGestureRecognizer
{
	if (!_activityGestureRecognizer) {
		_activityGestureRecognizer = [[RTSActivityGestureRecognizer alloc] initWithTarget:self action:@selector(resetIdleTimer)];
		_activityGestureRecognizer.delegate = self;
	}
	
	return _activityGestureRecognizer;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
{
	return [gestureRecognizer isKindOfClass:[RTSActivityGestureRecognizer class]];
}

- (RTSMediaPlayerView *)playerView
{
	return (RTSMediaPlayerView *)self.view;
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
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

#pragma mark - Overlays

- (NSArray *)overlayViews
{
	@synchronized(self) {
		if (!_overlayViews) {
			_overlayViews = @[ [UIView new] ];
		}
		return _overlayViews;
	}
}

- (void)setOverlayViews:(NSArray *)overlayViews
{
	@synchronized(self) {
		_overlayViews = overlayViews;
	}
}

- (void)handleSingleTap:(UITapGestureRecognizer *)gestureRecognizer
{
	[self toggleOverlays];
}

- (void)setOverlaysVisible:(BOOL)visible
{
	_overlaysVisible = visible;
	
	[self postNotificationName:visible ? RTSMediaPlayerWillShowControlOverlaysNotification : RTSMediaPlayerWillHideControlOverlaysNotification userInfo:nil];
	for (UIView *overlayView in self.overlayViews) {
		overlayView.hidden = !visible;
	}
	[self postNotificationName:visible ? RTSMediaPlayerDidShowControlOverlaysNotification : RTSMediaPlayerDidHideControlOverlaysNotification userInfo:nil];
}

- (void)toggleOverlays
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

- (void)resetIdleTimer
{
	int64_t delayInNanoseconds = ((self.overlayViewsHidingDelay > 0.0) ? self.overlayViewsHidingDelay : RTSMediaPlayerOverlayHidingDelay) * NSEC_PER_SEC;
	int64_t toleranceInNanoseconds = 0.1 * NSEC_PER_SEC;
	dispatch_source_set_timer(self.idleTimer, dispatch_time(DISPATCH_TIME_NOW, delayInNanoseconds), DISPATCH_TIME_FOREVER, toleranceInNanoseconds);
}

- (NSTimeInterval)overlayViewsHidingDelay
{
    return _overlayViewsHidingDelay;
}

- (void)setOverlayViewsHidingDelay:(NSTimeInterval)flag
{
	if (_overlayViewsHidingDelay != flag) {
		[self willChangeValueForKey:@"overlayViewsHidingDelay"];
		_overlayViewsHidingDelay = flag;
		[self didChangeValueForKey:@"overlayViewsHidingDelay"];
		[self resetIdleTimer];
	}
}

#pragma mark - Notifications

- (void)applicationWillResignActive:(NSNotification *)notification
{
	if ([self mediaType] == RTSMediaTypeVideo && !self.pictureInPictureController.isPictureInPictureActive) {
        [self.player pause];
        [self fireEvent:self.pauseEvent userInfo:nil];
	}
}

@end
