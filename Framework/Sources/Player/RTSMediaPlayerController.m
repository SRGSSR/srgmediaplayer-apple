//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <objc/runtime.h>

#import <libextobjc/EXTScope.h>

#import "RTSMediaPlayerController.h"

#import "RTSMediaPlayerError.h"
#import "RTSMediaPlayerView.h"
#import "RTSPeriodicTimeObserver.h"
#import "RTSActivityGestureRecognizer.h"
#import "RTSMediaPlayerLogger.h"

#import "NSBundle+RTSMediaPlayer.h"

static void *s_kvoContext = &s_kvoContext;

NSTimeInterval const RTSMediaPlayerOverlayHidingDelay = 5.0;
NSTimeInterval const RTSMediaLiveDefaultTolerance = 30.0;		// same tolerance as built-in iOS player

NSString * const RTSMediaPlayerErrorDomain = @"ch.srgssr.SRGMediaPlayer";

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

@interface RTSMediaPlayerController () <UIGestureRecognizerDelegate>

@property (readwrite) RTSMediaPlaybackState playbackState;
@property (readwrite) AVPlayer *player;
@property (readwrite) id periodicTimeObserver;
@property (readwrite) id playbackStartObserver;
@property (readwrite) CMTime previousPlaybackTime;
@property (readwrite) NSValue *startTimeValue;

@property (readwrite) NSMutableDictionary *periodicTimeObservers;

@property (readonly) RTSMediaPlayerView *playerView;
@property (readonly) RTSActivityGestureRecognizer *activityGestureRecognizer;

@property (readonly) dispatch_source_t idleTimer;

@property (nonatomic) AVPictureInPictureController *pictureInPictureController;

@end

@implementation RTSMediaPlayerController

@synthesize player = _player;
@synthesize view = _view;
@synthesize pictureInPictureController = _pictureInPictureController;
@synthesize overlayViews = _overlayViews;
@synthesize overlayViewsHidingDelay = _overlayViewsHidingDelay;
@synthesize activityGestureRecognizer = _activityGestureRecognizer;
@synthesize playbackState = _playbackState;
@synthesize idleTimer = _idleTimer;

#pragma mark - Initialization

- (instancetype)init
{
	if (self = [super init]) {
		_overlaysVisible = YES;
		
		self.overlayViewsHidingDelay = RTSMediaPlayerOverlayHidingDelay;
		self.periodicTimeObservers = [NSMutableDictionary dictionary];
		
		self.liveTolerance = RTSMediaLiveDefaultTolerance;
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_view removeFromSuperview];
	[_activityView removeGestureRecognizer:_activityGestureRecognizer];
	
	self.player = nil;
}

#pragma mark - Errors

static NSDictionary *ErrorUserInfo(RTSMediaPlayerError code, NSString *localizedDescription, NSError *underlyingError)
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	userInfo[NSLocalizedDescriptionKey] = localizedDescription ?: RTSMediaPlayerLocalizedString(@"An unknown error occurred", nil);
	userInfo[NSUnderlyingErrorKey] = underlyingError ?: [NSError errorWithDomain:RTSMediaPlayerErrorDomain
																			code:RTSMediaPlayerErrorUnknown
																		userInfo:@{ NSLocalizedDescriptionKey : RTSMediaPlayerLocalizedString(@"An unknown error occurred", nil) }];
	
	NSError *returnedError = [NSError errorWithDomain:RTSMediaPlayerErrorDomain
												 code:code
											 userInfo:userInfo];
	return @{ RTSMediaPlayerPlaybackDidFailErrorUserInfoKey : returnedError };
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

#pragma mark Playback

- (void)playURL:(NSURL *)URL
{}

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
		[_pictureInPictureController addObserver:self forKeyPath:@"pictureInPicturePossible" options:NSKeyValueObservingOptionNew context:s_kvoContext];
		[_pictureInPictureController addObserver:self forKeyPath:@"pictureInPictureActive" options:NSKeyValueObservingOptionNew context:s_kvoContext];
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
#if 0
			if ([self.stateMachine.currentState isEqual:self.playingState])
				[self setOverlaysVisible:NO];
#endif
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

@end
