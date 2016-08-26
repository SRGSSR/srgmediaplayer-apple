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

static NSTimeInterval const RTSMediaPlayerOverlayHidingDelay = 5.;

static NSError *RTSMediaPlayerControllerError(NSError *underlyingError)
{
	NSCParameterAssert(underlyingError);
	return [NSError errorWithDomain:RTSMediaPlayerErrorDomain code:RTSMediaPlayerErrorPlayback userInfo:@{ NSLocalizedDescriptionKey : RTSMediaPlayerLocalizedString(@"The media cannot be played", nil),
																										   NSUnderlyingErrorKey : underlyingError }];
}

@interface RTSMediaPlayerController ()

@property (nonatomic) NSURL *contentURL;
@property (nonatomic, readonly) RTSMediaPlayerView *playerView;
@property (nonatomic) RTSPlaybackState playbackState;
@property (nonatomic) NSMutableDictionary<NSString *, RTSPeriodicTimeObserver *> *periodicTimeObservers;
@property (nonatomic) RTSActivityGestureRecognizer *activityGestureRecognizer;
@property (nonatomic) AVPictureInPictureController *pictureInPictureController;
@property (nonatomic, getter=areOverlaysVisible) BOOL overlaysVisible;

@property (nonatomic) NSValue *startTimeValue;
@property (nonatomic, copy) void (^startCompletionHandler)(BOOL finished);

@end

@implementation RTSMediaPlayerController

@synthesize view = _view;
@synthesize activityView = _activityView;
@synthesize pictureInPictureController = _pictureInPictureController;

#pragma mark Object lifecycle

- (instancetype)init
{
	if (self = [super init]) {
		self.playbackState = RTSPlaybackStateIdle;
		self.periodicTimeObservers = [NSMutableDictionary dictionary];
		self.overlayViewsHidingDelay = RTSMediaPlayerOverlayHidingDelay;
	}
	return self;
}

- (void)dealloc
{
	self.player = nil;							// Unregister KVO and notifications
	self.pictureInPictureController = nil;		// Unregister KVO
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

- (void)setPlaybackState:(RTSPlaybackState)playbackState
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

- (AVPictureInPictureController *)pictureInPictureController
{
	if (!_pictureInPictureController) {
		// Ensure proper KVO registration
		self.pictureInPictureController = [[AVPictureInPictureController alloc] initWithPlayerLayer:self.playerView.playerLayer];
	}
	return _pictureInPictureController;
}

- (void)setPictureInPictureController:(AVPictureInPictureController *)pictureInPictureController
{
	if (_pictureInPictureController) {
		[_pictureInPictureController removeObserver:self forKeyPath:@"pictureInPicturePossible" context:s_kvoContext];
		[_pictureInPictureController removeObserver:self forKeyPath:@"pictureInPictureActive" context:s_kvoContext];
	}
	
	_pictureInPictureController = pictureInPictureController;
	
	if (pictureInPictureController) {
		[pictureInPictureController addObserver:self forKeyPath:@"pictureInPicturePossible" options:NSKeyValueObservingOptionNew context:s_kvoContext];
		[pictureInPictureController addObserver:self forKeyPath:@"pictureInPictureActive" options:NSKeyValueObservingOptionNew context:s_kvoContext];
	}
}

#pragma mark Playback

- (void)prepareToPlayURL:(NSURL *)URL atTime:(CMTime)startTime withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler
{
    if (! CMTIME_IS_VALID(startTime)) {
        startTime = kCMTimeZero;
    }
    
    self.contentURL = URL;
    self.startTimeValue = [NSValue valueWithCMTime:startTime];
    self.startCompletionHandler = completionHandler;
    
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
	
	self.playbackState = RTSPlaybackStateSeeking;
	[self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
		if (finished) {
			self.playbackState = (self.player.rate == 0.f) ? RTSPlaybackStatePaused : RTSPlaybackStatePlaying;
		}
	}];
}

- (void)reset
{

}

- (void)playURL:(NSURL *)URL
{
    [self playURL:URL atTime:kCMTimeZero];
}

- (void)playURL:(NSURL *)URL atTime:(CMTime)time
{
    [self prepareToPlayURL:URL atTime:time withCompletionHandler:^(BOOL finished) {
        if (finished) {
            [self togglePlayPause];
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
	self.playbackState = RTSPlaybackStateStalled;
}

- (void)rts_playerItemDidPlayToEndTime:(NSNotification *)notification
{
	self.playbackState = RTSPlaybackStateEnded;
}

- (void)rts_playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
	self.playbackState = RTSPlaybackStateIdle;
	
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
			if (self.player.rate == 0.f && self.playbackState == RTSPlaybackStateStalled) {
				[self.player play];
			}
			else if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
				self.playbackState = (self.player.rate == 0.f) ? RTSPlaybackStatePaused : RTSPlaybackStatePlaying;
                
                // Playback start. Use received start parameters
                if (self.startTimeValue) {
                    void (^completionBlock)(BOOL) = ^(BOOL finished) {
                        self.startTimeValue = nil;
                        
                        self.startCompletionHandler ? self.startCompletionHandler(finished) : nil;
                        self.startCompletionHandler = nil;
                    };
                    
                    CMTime startTime = self.startTimeValue.CMTimeValue;
                    
                    if (CMTIME_COMPARE_INLINE(startTime, ==, kCMTimeZero)) {
                        completionBlock(YES);
                    }
                    else {
                        // Call system method to avoid unwanted seek state in this special case
                        [self.player seekToTime:startTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                            completionBlock(finished);
                        }];
                    }
                }
			}
			else {
				self.playbackState = RTSPlaybackStateIdle;
				
				if (playerItem.status == AVPlayerItemStatusFailed) {
					NSError *error = RTSMediaPlayerControllerError(playerItem.error);
					[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerPlaybackDidFailNotification
																		object:self
																	  userInfo:@{ RTSMediaPlayerPlaybackDidFailErrorUserInfoKey : error }];
				}
			}
		}
        else if ([keyPath isEqualToString:@"pictureInPictureActive"] || [keyPath isEqualToString:@"pictureInPicturePossible"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerPictureInPictureStateChangeNotification object:self];
            
            // Always show overlays again when picture in picture is disabled
            if ([keyPath isEqualToString:@"pictureInPictureActive"] && !self.pictureInPictureController.isPictureInPictureActive) {
                self.overlaysVisible = YES;
            }
        }
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
