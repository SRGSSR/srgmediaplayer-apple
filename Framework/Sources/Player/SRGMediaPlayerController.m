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

static NSError *SRGMediaPlayerControllerError(NSError *underlyingError)
{
    NSCParameterAssert(underlyingError);
    return [NSError errorWithDomain:SRGMediaPlayerErrorDomain code:SRGMediaPlayerErrorPlayback userInfo:@{ NSLocalizedDescriptionKey: SRGMediaPlayerLocalizedString(@"The media cannot be played", nil),
                                                                                                           NSUnderlyingErrorKey: underlyingError }];
}

@interface SRGMediaPlayerController () {
@private
    SRGMediaPlayerPlaybackState _playbackState;
    BOOL _wasPreviousSegmentSelected;
}

@property (nonatomic) NSURL *contentURL;
@property (nonatomic) NSArray<id<SRGSegment>> *segments;
@property (nonatomic) NSDictionary *userInfo;

@property (nonatomic) NSArray<id<SRGSegment>> *visibleSegments;

@property (nonatomic) NSMutableDictionary<NSString *, SRGPeriodicTimeObserver *> *periodicTimeObservers;
@property (nonatomic) id segmentPeriodicTimeObserver;

@property (nonatomic, weak) id<SRGSegment> previousSegment;
@property (nonatomic, weak) id<SRGSegment> selectedSegment;

@property (nonatomic) AVPictureInPictureController *pictureInPictureController;

@property (nonatomic) NSValue *startTimeValue;
@property (nonatomic, copy) void (^startCompletionHandler)(void);

@end

@implementation SRGMediaPlayerController

@synthesize view = _view;
@synthesize pictureInPictureController = _pictureInPictureController;

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        _playbackState = SRGMediaPlayerPlaybackStateIdle;
        
        self.liveTolerance = SRGMediaPlayerLiveDefaultTolerance;
        self.periodicTimeObservers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    // No need to call -reset here, since -stop or -reset must be called for the controller to be deallocated
    self.pictureInPictureController = nil;              // Unregister KVO
}

#pragma mark Getters and setters

- (void)setPlayer:(AVPlayer *)player
{
    AVPlayer *previousPlayer = self.playerLayer.player;
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
    
    self.playerLayer.player = player;
    
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
    return (AVPlayerLayer *)self.view.layer;
}

- (void)setPlaybackState:(SRGMediaPlayerPlaybackState)playbackState withUserInfo:(NSDictionary *)userInfo
{
    NSAssert([NSThread isMainThread], @"Not the main thread. Ensure important changes must be notified on the main thread. Fix");
    
    if (_playbackState == playbackState) {
        return;
    }
    
    NSMutableDictionary *fullUserInfo = [@{ SRGMediaPlayerPreviousPlaybackStateKey: @(_playbackState) } mutableCopy];
    if (userInfo) {
        [fullUserInfo addEntriesFromDictionary:userInfo];
    }
    
    [self willChangeValueForKey:@"playbackState"];
    _playbackState = playbackState;
    [self didChangeValueForKey:@"playbackState"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                        object:self
                                                      userInfo:[fullUserInfo copy]];
}

- (void)setSegments:(NSArray<id<SRGSegment>> *)segments
{
    _segments = segments;
    
    // Reset the cached visible segment list
    _visibleSegments = nil;
}

- (NSArray<id<SRGSegment>> *)visibleSegments
{
    // Cached for faster access
    if (! _visibleSegments) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hidden == NO"];
        _visibleSegments = [self.segments filteredArrayUsingPredicate:predicate];
    }
    return _visibleSegments;
}

- (UIView *)view
{
    if (! _view) {
        _view = [[SRGMediaPlayerView alloc] init];
    }
    return _view;
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

- (SRGMediaPlayerMediaType)mediaType
{
    if (! self.player) {
        return SRGMediaPlayerMediaTypeUnknown;
    }
    
    NSArray *tracks = self.player.currentItem.tracks;
    if (tracks.count == 0) {
        return SRGMediaPlayerMediaTypeUnknown;
    }
    
    NSString *mediaType = [[tracks.firstObject assetTrack] mediaType];
    return [mediaType isEqualToString:AVMediaTypeVideo] ? SRGMediaPlayerMediaTypeVideo : SRGMediaPlayerMediaTypeAudio;
}

- (SRGMediaPlayerStreamType)streamType
{
    CMTimeRange timeRange = self.timeRange;
    
    if (CMTIMERANGE_IS_INVALID(timeRange)) {
        return SRGMediaPlayerStreamTypeUnknown;
    }
    else if (CMTIMERANGE_IS_EMPTY(timeRange)) {
        return SRGMediaPlayerStreamTypeLive;
    }
    else if (CMTIME_IS_INDEFINITE(self.player.currentItem.duration)) {
        return SRGMediaPlayerStreamTypeDVR;
    }
    else {
        return SRGMediaPlayerStreamTypeOnDemand;
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
    
    if (self.streamType == SRGMediaPlayerStreamTypeLive) {
        return YES;
    }
    else if (self.streamType == SRGMediaPlayerStreamTypeDVR) {
        return CMTimeGetSeconds(CMTimeSubtract(CMTimeRangeGetEnd(self.timeRange), playerItem.currentTime)) < self.liveTolerance;
    }
    else {
        return NO;
    }
}

- (AVPictureInPictureController *)pictureInPictureController
{
    // It is especially important to wait until the player layer is ready for display, otherwise the player might behave
    // incorrectly (not correctly pause when asked to) because of the picture in picture controller, even if not active.
    // Weird, but it seems the relationship between both is tight, see
    //   https://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/AdoptingMultitaskingOniPad/QuickStartForPictureInPicture.html)
    if (! _pictureInPictureController && self.playerLayer.readyForDisplay) {
        // Call the setter for KVO registration
        self.pictureInPictureController = [[AVPictureInPictureController alloc] initWithPlayerLayer:self.playerLayer];
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

- (void)prepareToPlayURL:(NSURL *)URL atTime:(CMTime)time withSegments:(NSArray<id<SRGSegment>> *)segments userInfo:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURL:URL atTime:time withSegments:segments selectedSegment:nil userInfo:userInfo completionHandler:completionHandler];
}

- (void)play
{
    [self.player play];
}

- (void)pause
{
    [self.player pause];
}

- (void)stop
{
    [self stopWithUserInfo:nil];
}

- (void)seekToTime:(CMTime)time withToleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL))completionHandler
{
    [self seekToTime:time withToleranceBefore:toleranceBefore toleranceAfter:toleranceAfter selectedSegment:nil completionHandler:completionHandler];
}

- (void)reset
{
    // Save previous state information
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (self.contentURL) {
        userInfo[SRGMediaPlayerPreviousContentURLKey] = self.contentURL;
    }
    if (self.userInfo) {
        userInfo[SRGMediaPlayerPreviousUserInfoKey] = self.userInfo;
    }
    
    // Reset player state before stopping (so that any state change notification reflects this new state)
    self.contentURL = nil;
    self.segments = nil;
    self.userInfo = nil;
    
    [self stopWithUserInfo:[userInfo copy]];
}

#pragma mark Playback (convenience methods)

- (void)prepareToPlayURL:(NSURL *)URL withCompletionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURL:URL atTime:kCMTimeZero withSegments:nil userInfo:nil completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL atTime:(CMTime)time withSegments:(NSArray<id<SRGSegment>> *)segments userInfo:(NSDictionary *)userInfo
{
    [self prepareToPlayURL:URL atTime:time withSegments:segments userInfo:userInfo completionHandler:^{
        [self play];
    }];
}

- (void)playURL:(NSURL *)URL
{
    [self playURL:URL atTime:kCMTimeZero withSegments:nil userInfo:nil];
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

- (void)seekEfficientlyToTime:(CMTime)time withCompletionHandler:(void (^)(BOOL))completionHandler
{
    [self seekToTime:time withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:completionHandler];
}

- (void)seekPreciselyToTime:(CMTime)time withCompletionHandler:(void (^)(BOOL))completionHandler
{
    [self seekToTime:time withToleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
}

#pragma mark Segment playback

- (void)prepareToPlayURL:(NSURL *)URL atIndex:(NSInteger)index inSegments:(NSArray<id<SRGSegment>> *)segments withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler
{
    if (index < 0 || index >= segments.count) {
        return;
    }
    
    [self prepareToPlayURL:URL atTime:kCMTimeZero withSegments:segments selectedSegment:segments[index] userInfo:userInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL atIndex:(NSInteger)index inSegments:(NSArray<id<SRGSegment>> *)segments withUserInfo:(NSDictionary *)userInfo
{
    [self prepareToPlayURL:URL atIndex:index inSegments:segments withUserInfo:userInfo completionHandler:^{
        [self play];
    }];
}

- (void)seekToSegmentAtIndex:(NSInteger)index withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (index < 0 || index >= self.segments.count) {
        return;
    }
    
    [self seekToSegment:self.segments[index] withCompletionHandler:completionHandler];
}

- (void)seekToSegment:(id<SRGSegment>)segment withCompletionHandler:(void (^)(BOOL))completionHandler
{
    if (! [self.segments containsObject:segment]) {
        return;
    }
    
    // If the segment is already the current one (and was selected by the user), simply return to the beginning (no end / start transition)
    if (self.currentSegment == segment && _wasPreviousSegmentSelected) {
        [self seekToTime:[segment timeRange].start withToleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero selectedSegment:nil completionHandler:completionHandler];
    }
    else {
        [self seekToTime:[segment timeRange].start withToleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero selectedSegment:segment completionHandler:completionHandler];
    }
}

#pragma mark Playback (internal). Time parameters are ignored when valid segments are provided

- (void)prepareToPlayURL:(NSURL *)URL atTime:(CMTime)time withSegments:(NSArray<id<SRGSegment>> *)segments selectedSegment:(id<SRGSegment>)selectedSegment userInfo:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler
{
    NSAssert(! selectedSegment || [segments containsObject:selectedSegment], @"Segment must be valid");
    
    if (selectedSegment) {
        time = [selectedSegment timeRange].start;
    }
    else if (! CMTIME_IS_VALID(time)) {
        time = kCMTimeZero;
    }
    
    [self reset];
    
    self.contentURL = URL;
    self.segments = segments;
    self.userInfo = userInfo;
    self.selectedSegment = selectedSegment;
    
    [self setPlaybackState:SRGMediaPlayerPlaybackStatePreparing withUserInfo:nil];
    
    self.startTimeValue = [NSValue valueWithCMTime:time];
    self.startCompletionHandler = completionHandler;
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:URL];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
}

- (void)seekToTime:(CMTime)time withToleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter selectedSegment:(id<SRGSegment>)selectedSegment completionHandler:(void (^)(BOOL))completionHandler
{
    NSAssert(! selectedSegment || [self.segments containsObject:selectedSegment], @"Segment must be valid");
    
    if (CMTIME_IS_INVALID(time) || self.player.currentItem.status != AVPlayerItemStatusReadyToPlay) {
        return;
    }
    
    [self setPlaybackState:SRGMediaPlayerPlaybackStateSeeking withUserInfo:nil];
    self.selectedSegment = selectedSegment;
    
    [self.player seekToTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter completionHandler:^(BOOL finished) {
        if (finished) {
            [self setPlaybackState:(self.player.rate == 0.f) ? SRGMediaPlayerPlaybackStatePaused : SRGMediaPlayerPlaybackStatePlaying withUserInfo:nil];
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
}

- (void)stopWithUserInfo:(NSDictionary *)userInfo
{
    if (self.pictureInPictureController.isPictureInPictureActive) {
        [self.pictureInPictureController stopPictureInPicture];
    }
    
    [self setPlaybackState:SRGMediaPlayerPlaybackStateIdle withUserInfo:userInfo];
    self.previousSegment = nil;
    
    self.startTimeValue = nil;
    self.startCompletionHandler = nil;
    
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
        
        // Ignore when seeking (if we are skipping a segment)
        if (self.playbackState == SRGMediaPlayerPlaybackStateSeeking) {
            return;
        }
        
        // Find the segment matching the current time (force the selected one if any)
        __block id<SRGSegment> currentSegment = self.selectedSegment;
        if (! currentSegment) {
            [self.segments enumerateObjectsUsingBlock:^(id<SRGSegment>  _Nonnull segment, NSUInteger idx, BOOL * _Nonnull stop) {
                if (CMTimeRangeContainsTime(segment.timeRange, time)) {
                    currentSegment = segment;
                    *stop = YES;
                }
            }];
        }
        
        // Segment transition notifications
        if (self.previousSegment != currentSegment) {
            if (self.previousSegment && ! [self.previousSegment isBlocked]) {
                NSMutableDictionary *userInfo = [@{ SRGMediaPlayerSegmentKey : self.previousSegment,
                                                    SRGMediaPlayerSelectedKey : @(_wasPreviousSegmentSelected) } mutableCopy];
                if (currentSegment && ! [currentSegment isBlocked]) {
                    userInfo[SRGMediaPlayerNextSegmentKey] = currentSegment;
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerSegmentDidEndNotification
                                                                    object:self
                                                                  userInfo:[userInfo copy]];
                _wasPreviousSegmentSelected = NO;
            }
            
            if (currentSegment) {
                if (! [currentSegment isBlocked]) {
                    _wasPreviousSegmentSelected = currentSegment && (currentSegment == self.selectedSegment);
                    
                    NSMutableDictionary *userInfo = [@{ SRGMediaPlayerSegmentKey : currentSegment,
                                                        SRGMediaPlayerSelectedKey : @(_wasPreviousSegmentSelected) } mutableCopy];
                    if (self.previousSegment && ! [self.previousSegment isBlocked]) {
                        userInfo[SRGMediaPlayerPreviousSegmentKey] = self.previousSegment;
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerSegmentDidStartNotification
                                                                        object:self
                                                                      userInfo:[userInfo copy]];
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerWillSkipBlockedSegmentNotification
                                                                        object:self
                                                                      userInfo:@{ SRGMediaPlayerSegmentKey : currentSegment }];
                    
                    [self seekPreciselyToTime:CMTimeRangeGetEnd([currentSegment timeRange]) withCompletionHandler:^(BOOL finished) {
                        if (finished) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerDidSkipBlockedSegmentNotification
                                                                                object:self
                                                                              userInfo:@{ SRGMediaPlayerSegmentKey : currentSegment }];
                        }
                    }];
                }
            }
            
            self.previousSegment = currentSegment;
        }
        
        self.selectedSegment = nil;
    }];
}

- (void)unregisterTimeObservers
{
    [self.player removeTimeObserver:self.segmentPeriodicTimeObserver];
    self.segmentPeriodicTimeObserver = nil;
    
    for (SRGPeriodicTimeObserver *periodicTimeObserver in [self.periodicTimeObservers allValues]) {
        [periodicTimeObserver detachFromMediaPlayer];
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
    for (NSString *key in self.periodicTimeObservers.allKeys) {
        SRGPeriodicTimeObserver *periodicTimeObserver = self.periodicTimeObservers[key];
        if (! [periodicTimeObserver hasBlockWithIdentifier:observer]) {
            continue;
        }
            
        [periodicTimeObserver removeBlockWithIdentifier:observer];
        
        // Remove the periodic time observer if not used anymore
        if (periodicTimeObserver.registrationCount == 0) {
            [self.periodicTimeObservers removeObjectForKey:key];
            return;
        }
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
    [self setPlaybackState:SRGMediaPlayerPlaybackStateStalled withUserInfo:nil];
}

- (void)srg_mediaPlayerController_playerItemDidPlayToEndTime:(NSNotification *)notification
{
    [self setPlaybackState:SRGMediaPlayerPlaybackStateEnded withUserInfo:nil];
}

- (void)srg_mediaPlayerController_playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
    self.startTimeValue = nil;
    self.startCompletionHandler = nil;
    
    [self setPlaybackState:SRGMediaPlayerPlaybackStateIdle withUserInfo:nil];
    
    NSError *error = SRGMediaPlayerControllerError(notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey]);
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
            if (self.player.rate == 0.f && self.playbackState == SRGMediaPlayerPlaybackStateStalled) {
                [self.player play];
            }
            else if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
                // Playback start. Use received start parameters, do not update the playback state yet, wait until the
                // completion handler has been executed (since it might immediately start playback)
                if (self.startTimeValue) {
                    void (^completionBlock)(BOOL) = ^(BOOL finished) {
                        NSAssert(finished, @"Finished must be YES, as no seek should be able to cancel the initial seek");
                        
                        // Reset start time first so that playback state induced change made in the completion handler
                        // does not loop back here
                        self.startTimeValue = nil;
                        
                        self.startCompletionHandler ? self.startCompletionHandler() : nil;
                        self.startCompletionHandler = nil;
                        
                        // If the state of the player was not changed in the completion handler (still preparing), update
                        // it
                        if (self.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
                            [self setPlaybackState:(self.player.rate == 0.f) ? SRGMediaPlayerPlaybackStatePaused : SRGMediaPlayerPlaybackStatePlaying withUserInfo:nil];
                        }
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
                // Update the playback state immediately, except when reaching the end. Non-streamed medias will namely reach the paused state right before
                // the item end notification is received. We can eliminate this pause by checking if we are at the end or not
                else if (CMTIME_COMPARE_INLINE(playerItem.currentTime, !=, CMTimeRangeGetEnd(self.timeRange))) {
                    [self setPlaybackState:(self.player.rate == 0.f) ? SRGMediaPlayerPlaybackStatePaused : SRGMediaPlayerPlaybackStatePlaying withUserInfo:nil];
                }
            }
            else {
                if (playerItem.status == AVPlayerItemStatusFailed) {
                    [self setPlaybackState:SRGMediaPlayerPlaybackStateIdle withUserInfo:nil];
                    
                    self.startTimeValue = nil;
                    self.startCompletionHandler = nil;
                    
                    NSError *error = SRGMediaPlayerControllerError(playerItem.error);
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
