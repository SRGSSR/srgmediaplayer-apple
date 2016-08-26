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

NSTimeInterval const RTSMediaPlayerOverlayHidingDelay = 5.;
NSTimeInterval const RTSMediaLiveDefaultTolerance = 30.;		// same tolerance as built-in iOS player

NSString * const RTSMediaPlayerPlaybackStateDidChangeNotification = @"RTSMediaPlayerPlaybackStateDidChangeNotification";
NSString * const RTSMediaPlayerPlaybackDidFailNotification = @"RTSMediaPlayerPlaybackDidFailNotification";

NSString * const RTSMediaPlayerPreviousPlaybackStateUserInfoKey = @"RTSMediaPlayerPreviousPlaybackState";
NSString * const RTSMediaPlayerPlaybackDidFailErrorUserInfoKey = @"RTSMediaPlayerPlaybackError";

static NSError *RTSMediaPlayerControllerError(NSError *underlyingError)
{
	NSCParameterAssert(underlyingError);
	return [NSError errorWithDomain:RTSMediaPlayerErrorDomain code:RTSMediaPlayerErrorPlayback userInfo:@{ NSLocalizedDescriptionKey : RTSMediaPlayerLocalizedString(@"The media cannot be played", nil),
																										   NSUnderlyingErrorKey : underlyingError }];
}

@interface RTSMediaPlayerController ()

@property (nonatomic, readonly) RTSMediaPlayerView *playerView;
@property (nonatomic) RTSMediaPlaybackState playbackState;
@property (nonatomic) NSMutableDictionary<NSString *, RTSPeriodicTimeObserver *> *periodicTimeObservers;
@property (nonatomic) RTSActivityGestureRecognizer *activityGestureRecognizer;

@end

@implementation RTSMediaPlayerController {
@private
	BOOL _seeking;
}

@synthesize view = _view;
@synthesize activityView = _activityView;

#pragma mark Object lifecycle

- (instancetype)init
{
	if (self = [super init]) {
		self.playbackState = RTSMediaPlaybackStateIdle;
		self.periodicTimeObservers = [NSMutableDictionary dictionary];
		self.overlayViewsHidingDelay = RTSMediaPlayerOverlayHidingDelay;
	}
	return self;
}

- (void)dealloc
{
	self.player = nil;			// Unregister KVO and notifications
}

#pragma mark Getters and setters

- (void)setPlayer:(AVPlayer *)player
{
	AVPlayer *previousPlayer = self.playerView.playerLayer.player;
	if (previousPlayer) {
		[self unregisterCustomPeriodicTimeObservers];
		
		[previousPlayer removeObserver:self forKeyPath:@"currentItem.status" context:s_kvoContext];
		[previousPlayer removeObserver:self forKeyPath:@"rate" context:s_kvoContext];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:AVPlayerItemPlaybackStalledNotification
													  object:previousPlayer.currentItem];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:AVPlayerItemDidPlayToEndTimeNotification
													  object:previousPlayer.currentItem];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:AVPlayerItemFailedToPlayToEndTimeNotification
													  object:previousPlayer.currentItem];
	}
	
	self.playerView.playerLayer.player = player;
	
	if (player) {
		[self registerCustomPeriodicTimeObserversForPlayer:player];
		
		[player addObserver:self
				 forKeyPath:@"currentItem.status"
					options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
					context:s_kvoContext];
		[player addObserver:self
				 forKeyPath:@"rate"
					options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
					context:s_kvoContext];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rts_playerItemPlaybackStalled:)
													 name:AVPlayerItemPlaybackStalledNotification
												   object:player.currentItem];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rts_playerItemDidPlayToEndTime:)
													 name:AVPlayerItemDidPlayToEndTimeNotification
												   object:player.currentItem];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rts_playerItemFailedToPlayToEndTime:)
													 name:AVPlayerItemFailedToPlayToEndTimeNotification
												   object:player.currentItem];
	}
}

- (AVPlayer *)player
{
	return self.playerView.playerLayer.player;
}

- (void)setPlaybackState:(RTSMediaPlaybackState)playbackState
{
	NSAssert([NSThread isMainThread], @"Not the main thread. Ensure important changes must be notified on the main thread. Fix");
	
	if (_playbackState == playbackState) {
		return;
	}
	
	[self willChangeValueForKey:@"playbackState"];
	_playbackState = playbackState;
	[self didChangeValueForKey:@"playbackState"];
	
	NSDictionary *userInfo = @{ RTSMediaPlayerPreviousPlaybackStateUserInfoKey: @(_playbackState) };
	[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerPlaybackStateDidChangeNotification
														object:self
													  userInfo:userInfo];
}

- (UIView *)view
{
	if (!_view) {
		_view = [[RTSMediaPlayerView alloc] init];
		
		UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rts_handleDoubleTap:)];
		doubleTapGestureRecognizer.numberOfTapsRequired = 2;
		[_view addGestureRecognizer:doubleTapGestureRecognizer];
		
		UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rts_handleSingleTap:)];
		[singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
		[_view addGestureRecognizer:singleTapGestureRecognizer];
		
		if (!self.activityView) {
			self.activityView = _view;
		}
	}
	return _view;
}

- (RTSMediaPlayerView *)playerView
{
	return (RTSMediaPlayerView *)self.view;
}

- (void)setActivityView:(UIView *)activityView
{
	[_activityView removeGestureRecognizer:self.activityGestureRecognizer];
	_activityView = activityView;
	[activityView addGestureRecognizer:self.activityGestureRecognizer];
}

- (RTSActivityGestureRecognizer *)activityGestureRecognizer
{
	if (!_activityGestureRecognizer) {
		_activityGestureRecognizer = [[RTSActivityGestureRecognizer alloc] initWithTarget:self action:@selector(rts_resetIdleTimer:)];
		_activityGestureRecognizer.delegate = self;
	}
	
	return _activityGestureRecognizer;
}

- (CMTimeRange)timeRange
{
	AVPlayerItem *playerItem = self.player.currentItem;
	
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
	if (CMTIME_IS_INDEFINITE(playerItem.duration) && CMTimeGetSeconds(timeRange.duration) < self.minimumDVRWindowLength) {
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
	else if (CMTIME_IS_INDEFINITE(self.player.currentItem.duration)) {
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
	AVPlayerItem *playerItem = self.player.currentItem;
	if (!playerItem) {
		return NO;
	}
	
	if (self.streamType == RTSMediaStreamTypeLive) {
		return YES;
	}
	else if (self.streamType == RTSMediaStreamTypeDVR) {
		return CMTimeGetSeconds(CMTimeSubtract(CMTimeRangeGetEnd(self.timeRange), playerItem.currentTime)) < self.liveTolerance;
	}
	else {
		return NO;
	}
}

#pragma mark Playback

- (void)playURL:(NSURL *)URL
{
	AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:URL];
	self.player = [AVPlayer playerWithPlayerItem:playerItem];
}

- (void)togglePlayPause
{
	if (self.player.rate == 0.f) {
		[self.player play];
	}
	else {
		[self.player pause];
	}
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler
{
	if (CMTIME_IS_INVALID(time) || self.player.currentItem.status != AVPlayerItemStatusReadyToPlay) {
		completionHandler ? completionHandler(NO) : nil;
		return;
	}
	
	self.playbackState = RTSMediaPlaybackStateSeeking;
	[self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
		if (finished) {
			self.playbackState = (self.player.rate == 0.f) ? RTSMediaPlaybackStatePaused : RTSMediaPlaybackStatePlaying;
		}
	}];
}

#pragma mark Time observers

- (void)registerCustomPeriodicTimeObserversForPlayer:(AVPlayer *)player
{
	[self unregisterCustomPeriodicTimeObservers];
	
	for (RTSPeriodicTimeObserver *playbackBlockRegistration in [self.periodicTimeObservers allValues]) {
		[playbackBlockRegistration attachToMediaPlayer:player];
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

#pragma mark UIGestureRecognizerDelegate protocols

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return [gestureRecognizer isKindOfClass:[RTSActivityGestureRecognizer class]];
}

#pragma mark Notifications

- (void)rts_playerItemPlaybackStalled:(NSNotification *)notification
{
	self.playbackState = RTSMediaPlaybackStateStalled;
}

- (void)rts_playerItemDidPlayToEndTime:(NSNotification *)notification
{
	self.playbackState = RTSMediaPlaybackStateEnded;
}

- (void)rts_playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
	self.playbackState = RTSMediaPlaybackStateIdle;
	
	NSError *error = RTSMediaPlayerControllerError(notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey]);
	[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerPlaybackDidFailNotification
														object:self
													  userInfo:@{ RTSMediaPlayerPlaybackDidFailErrorUserInfoKey : error }];
}

#pragma mark Gesture recognizers

- (void)rts_handleSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
	NSLog(@"Single tap");
}

- (void)rts_handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
	AVPlayerLayer *playerLayer = self.playerView.playerLayer;
	
	if (!playerLayer.isReadyForDisplay) {
		return;
	}
	
	if ([playerLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
		playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	}
	else {
		playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
	}
}

- (void)rts_resetIdleTimer:(UIGestureRecognizer *)gestureRecognizer
{
	NSLog(@"Reset timer");
}

#pragma mark KVO

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	if ([key isEqualToString:@"playbackState"]) {
		return NO;
	}
	else {
		return [super automaticallyNotifiesObserversForKey:key];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	NSAssert([NSThread isMainThread], @"Not the main thread. Ensure important changes must be notified on the main thread. Fix");
	
	// TODO: Warning: Might not be executed on the main thread!
	if (context == s_kvoContext) {
		NSLog(@"KVO change for %@ with change %@", keyPath, change);
		
		// If the rate or the item status changes, calculate the new playback status
		if ([keyPath isEqualToString:@"currentItem.status"] || [keyPath isEqualToString:@"rate"]) {
			AVPlayerItem *playerItem = self.player.currentItem;
			
			// Do not let playback pause when the player stalls, attempt to play again
			if (self.player.rate == 0.f && self.playbackState == RTSMediaPlaybackStateStalled) {
				[self.player play];
			}
			else if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
				self.playbackState = (self.player.rate == 0.f) ? RTSMediaPlaybackStatePaused : RTSMediaPlaybackStatePlaying;
			}
			else {
				self.playbackState = RTSMediaPlaybackStateIdle;
				
				if (playerItem.status == AVPlayerItemStatusFailed) {
					NSError *error = RTSMediaPlayerControllerError(playerItem.error);
					[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerPlaybackDidFailNotification
																		object:self
																	  userInfo:@{ RTSMediaPlayerPlaybackDidFailErrorUserInfoKey : error }];
				}
			}
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
