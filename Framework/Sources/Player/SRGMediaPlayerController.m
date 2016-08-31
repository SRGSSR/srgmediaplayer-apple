//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import "NSBundle+SRGMediaPlayer.h"
#import "SRGMediaPlayerError.h"
#import "SRGMediaPlayerView.h"
#import "SRGPeriodicTimeObserver.h"
#import "SRGActivityGestureRecognizer.h"
#import "SRGMediaPlayerLogger.h"

#import <libextobjc/EXTScope.h>
#import <objc/runtime.h>

static void *s_kvoContext = &s_kvoContext;

static NSError *RTSMediaPlayerControllerError(NSError *underlyingError)
{
    NSCParameterAssert(underlyingError);
    return [NSError errorWithDomain:SRGMediaPlayerErrorDomain code:SRGMediaPlayerErrorPlayback userInfo:@{ NSLocalizedDescriptionKey: RTSMediaPlayerLocalizedString(@"The media cannot be played", nil),
                                                                                                           NSUnderlyingErrorKey: underlyingError }];
}

@interface SRGMediaPlayerController ()

@property (nonatomic) NSURL *contentURL;
@property (nonatomic) NSArray<id<SRGSegment>> *segments;

@property (nonatomic, readonly) SRGMediaPlayerView *playerView;
@property (nonatomic) SRGPlaybackState playbackState;

@property (nonatomic) NSMutableDictionary<NSString *, SRGPeriodicTimeObserver *> *periodicTimeObservers;
@property (nonatomic) id segmentPeriodicTimeObserver;

@property (nonatomic) id<SRGSegment> previousSegment;

@property (nonatomic) AVPictureInPictureController *pictureInPictureController;

@property (nonatomic) NSValue *startTimeValue;
@property (nonatomic, copy) void (^startCompletionHandler)(BOOL finished);

@end

@implementation SRGMediaPlayerController

@synthesize view = _view;
@synthesize pictureInPictureController = _pictureInPictureController;

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.playbackState = SRGPlaybackStateIdle;
        self.liveTolerance = SRGLiveDefaultTolerance;
        self.periodicTimeObservers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    [self reset];
    self.pictureInPictureController = nil;              // Unregister KVO
}

#pragma mark Getters and setters

- (void)setPlayer:(AVPlayer *)player
{
    AVPlayer *previousPlayer = self.playerView.playerLayer.player;
    if (previousPlayer) {
        [self unregisterTimeObservers];
        
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
        
        self.playerDestructionBlock ? self.playerDestructionBlock(previousPlayer) : nil;
    }
    
    self.playerView.playerLayer.player = player;
    
    if (player) {
        [self registerTimeObserversForPlayer:player];
        
        [player addObserver:self
                 forKeyPath:@"currentItem.status"
                    options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                    context:s_kvoContext];
        [player addObserver:self
                 forKeyPath:@"rate"
                    options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                    context:s_kvoContext];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_mediaPlayerController_playerItemPlaybackStalled:)
                                                     name:AVPlayerItemPlaybackStalledNotification
                                                   object:player.currentItem];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_mediaPlayerController_playerItemDidPlayToEndTime:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:player.currentItem];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_mediaPlayerController_playerItemFailedToPlayToEndTime:)
                                                     name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                   object:player.currentItem];
        
        self.playerCreationBlock ? self.playerCreationBlock(player) : nil;
        self.playerConfigurationBlock ? self.playerConfigurationBlock(player) : nil;
    }
}

- (AVPlayer *)player
{
    return self.playerLayer.player;
}

- (AVPlayerLayer *)playerLayer
{
    return self.playerView.playerLayer;
}

- (void)setPlaybackState:(SRGPlaybackState)playbackState
{
    NSAssert([NSThread isMainThread], @"Not the main thread. Ensure important changes must be notified on the main thread. Fix");
    
    if (_playbackState == playbackState) {
        return;
    }
    
    NSDictionary *userInfo = @{ SRGMediaPlayerPreviousPlaybackStateKey: @(_playbackState) };
    
    [self willChangeValueForKey:@"playbackState"];
    _playbackState = playbackState;
    [self didChangeValueForKey:@"playbackState"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (UIView *)view
{
    if (! _view) {
        _view = [[SRGMediaPlayerView alloc] init];
    }
    return _view;
}

- (SRGMediaPlayerView *)playerView
{
    return (SRGMediaPlayerView *)self.view;
}

- (CMTimeRange)timeRange
{
    AVPlayerItem *playerItem = self.player.currentItem;
    
    NSValue *firstSeekableTimeRangeValue = [playerItem.seekableTimeRanges firstObject];
    if (! firstSeekableTimeRangeValue) {
        return kCMTimeRangeInvalid;
    }
    
    NSValue *lastSeekableTimeRangeValue = [playerItem.seekableTimeRanges lastObject];
    if (! lastSeekableTimeRangeValue) {
        return kCMTimeRangeInvalid;
    }
    
    CMTimeRange firstSeekableTimeRange = [firstSeekableTimeRangeValue CMTimeRangeValue];
    CMTimeRange lastSeekableTimeRange = [lastSeekableTimeRangeValue CMTimeRangeValue];
    
    if (! CMTIMERANGE_IS_VALID(firstSeekableTimeRange) || ! CMTIMERANGE_IS_VALID(lastSeekableTimeRange)) {
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

- (SRGMediaType)mediaType
{
    if (! self.player) {
        return SRGMediaTypeUnknown;
    }
    
    NSArray *tracks = self.player.currentItem.tracks;
    if (tracks.count == 0) {
        return SRGMediaTypeUnknown;
    }
    
    NSString *mediaType = [[tracks.firstObject assetTrack] mediaType];
    return [mediaType isEqualToString:AVMediaTypeVideo] ? SRGMediaTypeVideo : SRGMediaTypeAudio;
}

- (SRGMediaStreamType)streamType
{
    CMTimeRange timeRange = self.timeRange;
    
    if (CMTIMERANGE_IS_INVALID(timeRange)) {
        return SRGMediaStreamTypeUnknown;
    }
    else if (CMTIMERANGE_IS_EMPTY(timeRange)) {
        return SRGMediaStreamTypeLive;
    }
    else if (CMTIME_IS_INDEFINITE(self.player.currentItem.duration)) {
        return SRGMediaStreamTypeDVR;
    }
    else {
        return SRGMediaStreamTypeOnDemand;
    }
}

- (void)setMinimumDVRWindowLength:(NSTimeInterval)minimumDVRWindowLength
{
    if (minimumDVRWindowLength < 0.) {
        SRGMediaPlayerLogWarning(@"The minimum DVR window length cannot be negative. Set to 0");
        _minimumDVRWindowLength = 0.;
    }
    else {
        _minimumDVRWindowLength = minimumDVRWindowLength;
    }
}

- (void)setLiveTolerance:(NSTimeInterval)liveTolerance
{
    if (liveTolerance < 0.) {
        SRGMediaPlayerLogWarning(@"Live tolerance cannot be negative. Set to 0");
        _liveTolerance = 0.;
    }
    else {
        _liveTolerance = liveTolerance;
    }
}

- (BOOL)isLive
{
    AVPlayerItem *playerItem = self.player.currentItem;
    if (! playerItem) {
        return NO;
    }
    
    if (self.streamType == SRGMediaStreamTypeLive) {
        return YES;
    }
    else if (self.streamType == SRGMediaStreamTypeDVR) {
        return CMTimeGetSeconds(CMTimeSubtract(CMTimeRangeGetEnd(self.timeRange), playerItem.currentTime)) < self.liveTolerance;
    }
    else {
        return NO;
    }
}

- (AVPictureInPictureController *)pictureInPictureController
{
    if (! _pictureInPictureController) {
        // Call the setter for KVO registration
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

- (void)prepareToPlayURL:(NSURL *)URL atTime:(CMTime)startTime withSegments:(NSArray<id<SRGSegment>> *)segments completionHandler:(void (^)(BOOL))completionHandler
{
    if (! CMTIME_IS_VALID(startTime)) {
        startTime = kCMTimeZero;
    }
    
    [self reset];
    
    self.contentURL = URL;
    self.segments = segments;
    self.startTimeValue = [NSValue valueWithCMTime:startTime];
    self.startCompletionHandler = completionHandler;
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:URL];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
}

- (void)prepareToPlayURL:(NSURL *)URL atTime:(CMTime)startTime withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler
{
    [self prepareToPlayURL:URL atTime:startTime withSegments:nil completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL atTime:(CMTime)time withSegments:(nullable NSArray<id<SRGSegment>> *)segments
{
    [self prepareToPlayURL:URL atTime:time withSegments:segments completionHandler:^(BOOL finished) {
        if (finished) {
            [self togglePlayPause];
        }
    }];
}

- (void)playURL:(NSURL *)URL atTime:(CMTime)time
{
    [self playURL:URL atTime:time withSegments:nil];
}

- (void)playURL:(NSURL *)URL withSegments:(NSArray<id<SRGSegment>> *)segments
{
    [self playURL:URL atTime:kCMTimeZero withSegments:segments];
}

- (void)playURL:(NSURL *)URL
{
    [self playURL:URL atTime:kCMTimeZero];
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

- (void)seekToTime:(CMTime)time withCompletionHandler:(void (^)(BOOL))completionHandler
{
    if (CMTIME_IS_INVALID(time) || self.player.currentItem.status != AVPlayerItemStatusReadyToPlay) {
        completionHandler ? completionHandler(NO) : nil;
        return;
    }
    
    self.playbackState = SRGPlaybackStateSeeking;
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        if (finished) {
            self.playbackState = (self.player.rate == 0.f) ? SRGPlaybackStatePaused : SRGPlaybackStatePlaying;
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
}

- (void)seekToSegment:(id<SRGSegment>)segment withCompletionHandler:(void (^)(BOOL))completionHandler
{
    CMTime time = [segment timeRange].start;
    [self seekToTime:time withCompletionHandler:completionHandler];
}

- (void)reset
{
    if (self.pictureInPictureController.isPictureInPictureActive) {
        [self.pictureInPictureController stopPictureInPicture];
    }
    
    self.playbackState = SRGPlaybackStateIdle;
    
    [self.player pause];
    self.player = nil;
}

#pragma mark Configuration

- (void)reloadPlayerConfiguration
{
    if (self.player) {
        self.playerConfigurationBlock ? self.playerConfigurationBlock(self.player) : nil;
    }
}

#pragma mark Time observers

- (void)registerTimeObserversForPlayer:(AVPlayer *)player
{
    for (SRGPeriodicTimeObserver *playbackBlockRegistration in [self.periodicTimeObservers allValues]) {
        [playbackBlockRegistration attachToMediaPlayer:player];
    }
    
    @weakify(self)
    self.segmentPeriodicTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        
        __block id<SRGSegment> currentSegment = nil;
        [self.segments enumerateObjectsUsingBlock:^(id<SRGSegment>  _Nonnull segment, NSUInteger idx, BOOL * _Nonnull stop) {
            if (CMTimeRangeContainsTime(segment.timeRange, time)) {
                currentSegment = segment;
                *stop = YES;
            }
        }];
        
        if (self.previousSegment != currentSegment) {
            if (self.previousSegment) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerSegmentDidEndNotification
                                                                    object:self
                                                                  userInfo:@{ SRGMediaPlayerSegmentKey : self.previousSegment }];
            }
            
            if (currentSegment) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerSegmentDidStartNotification
                                                                    object:self
                                                                  userInfo:@{ SRGMediaPlayerSegmentKey : currentSegment }];
            }
            
            self.previousSegment = currentSegment;
        }
    }];
}

- (void)unregisterTimeObservers
{
    [self.player removeTimeObserver:self.segmentPeriodicTimeObserver];
    self.segmentPeriodicTimeObserver = nil;
    
    for (SRGPeriodicTimeObserver *playbackBlockRegistration in [self.periodicTimeObservers allValues]) {
        [playbackBlockRegistration detachFromMediaPlayer];
    }
}

- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block
{
    if (! block) {
        return nil;
    }
    
    NSString *identifier = [[NSUUID UUID] UUIDString];
    SRGPeriodicTimeObserver *periodicTimeObserver = [self periodicTimeObserverForInterval:interval queue:queue];
    [periodicTimeObserver setBlock:block forIdentifier:identifier];
    
    if (self.player) {
        [periodicTimeObserver attachToMediaPlayer:self.player];
    }
    
    // Return the opaque identifier
    return identifier;
}

- (void)removePeriodicTimeObserver:(id)observer
{
    for (SRGPeriodicTimeObserver *periodicTimeObserver in [self.periodicTimeObservers allValues]) {
        [periodicTimeObserver removeBlockWithIdentifier:observer];
    }
}

- (SRGPeriodicTimeObserver *)periodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue
{
    NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@-%p", @(interval.value), @(interval.timescale), @(interval.flags), @(interval.epoch), queue];
    SRGPeriodicTimeObserver *periodicTimeObserver = self.periodicTimeObservers[key];
    
    if (! periodicTimeObserver) {
        periodicTimeObserver = [[SRGPeriodicTimeObserver alloc] initWithInterval:interval queue:queue];
        self.periodicTimeObservers[key] = periodicTimeObserver;
    }
    
    return periodicTimeObserver;
}

#pragma mark Notifications

- (void)srg_mediaPlayerController_playerItemPlaybackStalled:(NSNotification *)notification
{
    self.playbackState = SRGPlaybackStateStalled;
}

- (void)srg_mediaPlayerController_playerItemDidPlayToEndTime:(NSNotification *)notification
{
    self.playbackState = SRGPlaybackStateEnded;
}

- (void)srg_mediaPlayerController_playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
    self.playbackState = SRGPlaybackStateIdle;
    
    NSError *error = RTSMediaPlayerControllerError(notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey]);
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerPlaybackDidFailNotification
                                                        object:self
                                                      userInfo:@{ SRGMediaPlayerErrorKey: error }];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context
{
    NSAssert([NSThread isMainThread], @"Not the main thread. Ensure important changes must be notified on the main thread. Fix");
    
    if (context == s_kvoContext) {
        // If the rate or the item status changes, calculate the new playback status
        if ([keyPath isEqualToString:@"currentItem.status"] || [keyPath isEqualToString:@"rate"]) {
            AVPlayerItem *playerItem = self.player.currentItem;
            
            // Do not let playback pause when the player stalls, attempt to play again
            if (self.player.rate == 0.f && self.playbackState == SRGPlaybackStateStalled) {
                [self.player play];
            }
            else if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
                self.playbackState = (self.player.rate == 0.f) ? SRGPlaybackStatePaused : SRGPlaybackStatePlaying;
                
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
                self.playbackState = SRGPlaybackStateIdle;
                
                if (playerItem.status == AVPlayerItemStatusFailed) {
                    NSError *error = RTSMediaPlayerControllerError(playerItem.error);
                    [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerPlaybackDidFailNotification
                                                                        object:self
                                                                      userInfo:@{ SRGMediaPlayerErrorKey: error }];
                }
            }
        }
        else if ([keyPath isEqualToString:@"pictureInPictureActive"] || [keyPath isEqualToString:@"pictureInPicturePossible"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerPictureInPictureStateDidChangeNotification object:self];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
