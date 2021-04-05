//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import "AVAudioSession+SRGMediaPlayer.h"
#import "AVMediaSelectionGroup+SRGMediaPlayer.h"
#import "AVPlayerItem+SRGMediaPlayer.h"
#import "CMTime+SRGMediaPlayer.h"
#import "CMTimeRange+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "NSTimer+SRGMediaPlayer.h"
#import "SRGActivityGestureRecognizer.h"
#import "SRGMediaAccessibility.h"
#import "SRGMediaPlayerError.h"
#import "SRGMediaPlayerLogger.h"
#import "SRGMediaPlayerView.h"
#import "SRGMediaPlayerView+Private.h"
#import "SRGPeriodicTimeObserver.h"
#import "SRGPlayer.h"
#import "SRGSegment+Private.h"
#import "SRGTimePosition.h"
#import "UIDevice+SRGMediaPlayer.h"
#import "UIScreen+SRGMediaPlayer.h"

#import <objc/runtime.h>

@import libextobjc;
@import MAKVONotificationCenter;

static CMTime SRGSafeSeekOffset(void)
{
    return CMTimeMakeWithSeconds(0.1, NSEC_PER_SEC);
}

static CMTime SRGSafeStartSeekOffset(void)
{
    return [AVAudioSession srg_isBluetoothHeadsetActive] ? CMTimeMakeWithSeconds(0.3, NSEC_PER_SEC) : SRGSafeSeekOffset();
}

static NSError *SRGMediaPlayerControllerError(NSError *underlyingError);
static NSString *SRGMediaPlayerControllerNameForPlaybackState(SRGMediaPlayerPlaybackState playbackState);
static NSString *SRGMediaPlayerControllerNameForMediaType(SRGMediaPlayerMediaType mediaType);
static NSString *SRGMediaPlayerControllerNameForStreamType(SRGMediaPlayerStreamType streamType);

static SRGTimePosition *SRGMediaPlayerControllerPositionInTimeRange(SRGTimePosition *timePosition, CMTimeRange timeRange, CMTime startOffset, CMTime endOffset);

static AVMediaSelectionOption *SRGMediaPlayerControllerAutomaticAudioDefaultOption(NSArray<AVMediaSelectionOption *> *audioOptions);
static AVMediaSelectionOption *SRGMediaPlayerControllerAutomaticSubtitleDefaultOption(NSArray<AVMediaSelectionOption *> *subtitleOptions, AVMediaSelectionOption *audioOption);
static AVMediaSelectionOption *SRGMediaPlayerControllerSubtitleDefaultOption(NSArray<AVMediaSelectionOption *> *subtitleOptions, AVMediaSelectionOption *audioOption);
static AVMediaSelectionOption *SRGMediaPlayerControllerSubtitleDefaultLanguageOption(NSArray<AVMediaSelectionOption *> *subtitleOptions, NSString *language, NSArray<AVMediaCharacteristic> *characteristics);

@interface SRGMediaPlayerController () <SRGMediaPlayerViewDelegate, SRGPlayerDelegate> {
@private
    SRGMediaPlayerPlaybackState _playbackState;
    BOOL _selected;
    CMTimeRange _timeRange;
    SRGMediaPlayerStreamType _streamType;
    BOOL _live;
}

@property (nonatomic) SRGPlayer *player;

@property (nonatomic) NSURL *contentURL;
@property (nonatomic) AVURLAsset *URLAsset;
@property (nonatomic) NSDictionary *userInfo;

@property (nonatomic, copy) void (^playerCreationBlock)(AVPlayer *player);
@property (nonatomic, copy) void (^playerConfigurationBlock)(AVPlayer *player);
@property (nonatomic, copy) void (^playerDestructionBlock)(AVPlayer *player);

@property (nonatomic, copy) AVMediaSelectionOption * (^audioConfigurationBlock)(NSArray<AVMediaSelectionOption *> *audioOptions, AVMediaSelectionOption *defaultAudioOption);
@property (nonatomic, copy) AVMediaSelectionOption * (^subtitleConfigurationBlock)(NSArray<AVMediaSelectionOption *> *subtitleOptions, AVMediaSelectionOption *audioOption, AVMediaSelectionOption *defaultAudioOption);

@property (nonatomic) SRGMediaPlayerViewBackgroundBehavior viewBackgroundBehavior;

@property (nonatomic, readonly) SRGMediaPlayerPlaybackState playbackState;

@property (nonatomic) NSArray<id<SRGSegment>> *loadedSegments;
@property (nonatomic) NSArray<id<SRGSegment>> *visibleSegments;

@property (nonatomic) NSMutableDictionary<NSString *, SRGPeriodicTimeObserver *> *periodicTimeObservers;
@property (nonatomic) id playerPeriodicTimeObserver;        // AVPlayer time observer, needs to be retained according to the documentation
@property (nonatomic, weak) id controllerPeriodicTimeObserver;

@property (nonatomic) SRGMediaPlayerMediaType mediaType;
@property (nonatomic, getter=isTimeRangeCached) BOOL playbackInformationCached;

@property (nonatomic) CMTime referenceTime;
@property (nonatomic) NSDate *referenceDate;

@property (nonatomic) NSTimer *stallDetectionTimer;
@property (nonatomic) CMTime lastPlaybackTime;
@property (nonatomic) NSDate *lastStallDetectionDate;

// Saved values supplied when playback is started
@property (nonatomic, weak) id<SRGSegment> initialTargetSegment;
@property (nonatomic) SRGPosition *initialPosition;

@property (nonatomic, weak) id<SRGSegment> previousSegment;
@property (nonatomic, weak) id<SRGSegment> currentSegment;

@property (nonatomic, weak) id<SRGSegment> targetSegment;           // Will be nilled when reached
@property (nonatomic) SRGMediaPlayerSelectionReason selectionReason;

@property (nonatomic) AVPictureInPictureController *pictureInPictureController API_AVAILABLE(ios(9.0), tvos(14.0));
@property (nonatomic, copy) void (^pictureInPictureControllerCreationBlock)(AVPictureInPictureController *pictureInPictureController) API_AVAILABLE(ios(9.0), tvos(14.0));
@property (nonatomic) NSNumber *savedAllowsExternalPlayback;

@property (nonatomic) NSNumber *savedPreventsDisplaySleepDuringVideoPlayback API_AVAILABLE(ios(12.0), tvos(12.0));

@property (nonatomic) SRGPosition *startPosition;                   // Will be nilled when reached
@property (nonatomic, copy) void (^startCompletionHandler)(void);

@property (nonatomic) NSValue *presentationSizeValue;

@property (nonatomic) AVMediaSelectionOption *audioOption;
@property (nonatomic) AVMediaSelectionOption *subtitleOption;

@property (nonatomic, weak) AVPlayerViewController *playerViewController;

@end

@implementation SRGMediaPlayerController

@synthesize view = _view;

@synthesize pictureInPictureController = _pictureInPictureController;

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        _playbackState = SRGMediaPlayerPlaybackStateIdle;
        
        self.liveTolerance = SRGMediaPlayerDefaultLiveTolerance;
        self.endTolerance = SRGMediaPlayerDefaultEndTolerance;
        self.endToleranceRatio = SRGMediaPlayerDefaultEndToleranceRatio;
        
        self.periodicTimeObservers = [NSMutableDictionary dictionary];
        
        self.lastPlaybackTime = kCMTimeIndefinite;
    }
    return self;
}

- (void)dealloc
{
    [self reset];
}

#pragma mark Getters and setters

- (void)setPlayer:(SRGPlayer *)player
{
    BOOL hadPlayer = (_player != nil);
    
    if (_player) {
        [self unregisterTimeObserversForPlayer:_player];
        
        [_player removeObserver:self keyPath:@keypath(_player.currentItem.status)];
        [_player removeObserver:self keyPath:@keypath(_player.rate)];
        [_player removeObserver:self keyPath:@keypath(_player.externalPlaybackActive)];
        [_player removeObserver:self keyPath:@keypath(_player.currentItem.presentationSize)];
        
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:AVPlayerItemDidPlayToEndTimeNotification
                                                    object:_player.currentItem];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                    object:_player.currentItem];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UIApplicationDidEnterBackgroundNotification
                                                    object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UIApplicationWillEnterForegroundNotification
                                                    object:nil];
        
        self.playerDestructionBlock ? self.playerDestructionBlock(_player) : nil;
    }
    
    _player = player;
    [self attachPlayer:player toView:self.view];
    
    if (player) {
        if (! hadPlayer) {
            self.playerCreationBlock ? self.playerCreationBlock(player) : nil;
        }
        
        [self registerTimeObserversForPlayer:player];
        
        @weakify(self) @weakify(player)
        [player srg_addMainThreadObserver:self keyPath:@keypath(player.currentItem.status) options:0 block:^(MAKVONotification *notification) {
            @strongify(self) @strongify(player)
            
            AVPlayerItem *playerItem = player.currentItem;
            if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
                [self updatePlaybackInformationForPlayer:player];
                
                // Playback start. Use received start parameters, do not update the playback state yet, wait until the
                // completion handler has been executed (since it might immediately start playback)
                if (self.startPosition) {
                    void (^completionBlock)(BOOL) = ^(BOOL finished) {
                        if (! finished) {
                            return;
                        }
                        
                        self.view.playbackViewHidden = NO;
                        
                        // Reset start time first so that the playback state induced change made in the completion handler
                        // does not loop back here
                        self.startPosition = nil;
                        
                        self.startCompletionHandler ? self.startCompletionHandler() : nil;
                        self.startCompletionHandler = nil;
                        
                        // If the state of the player was not changed in the completion handler (still preparing), update
                        // it
                        if (self.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
                            [self setPlaybackState:(player.rate == 0.f) ? SRGMediaPlayerPlaybackStatePaused : SRGMediaPlayerPlaybackStatePlaying withUserInfo:nil];
                        }
                    };
                    
                    SRGTimePosition *startTimePosition = [self timePositionForPosition:self.startPosition inSegment:self.targetSegment applyEndTolerance:YES];
                    if (CMTIME_COMPARE_INLINE(startTimePosition.time, ==, kCMTimeZero)) {
                        // Default position. Nothing to do.
                        completionBlock(YES);
                    }
                    else {
                        if (CMTIME_COMPARE_INLINE(startTimePosition.time, !=, kCMTimeZero)) {
                            [player seekToTime:startTimePosition.time toleranceBefore:startTimePosition.toleranceBefore toleranceAfter:startTimePosition.toleranceAfter notify:NO completionHandler:^(BOOL finished) {
                                completionBlock(finished);
                            }];
                        }
                        else {
                            completionBlock(YES);
                        }
                    }
                }
            }
            else if (playerItem.status == AVPlayerItemStatusFailed) {
                [self stopWithUserInfo:nil];
                
                NSError *error = SRGMediaPlayerControllerError(playerItem.error);
                [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerPlaybackDidFailNotification
                                                                  object:self
                                                                userInfo:@{ SRGMediaPlayerErrorKey: error }];
                
                SRGMediaPlayerLogDebug(@"Controller", @"Playback did fail with error: %@", error);
            }
        }];
        
        [player srg_addMainThreadObserver:self keyPath:@keypath(player.rate) options:0 block:^(MAKVONotification *notification) {
            @strongify(self) @strongify(player)
            
            AVPlayerItem *playerItem = player.currentItem;
            
            // Only respond to rate changes when the item is ready to play 
            if (playerItem.status != AVPlayerItemStatusReadyToPlay) {
                return;
            }
            
            CMTime currentTime = playerItem.currentTime;
            CMTimeRange timeRange = self.timeRange;
            
            // Update the playback state immediately, except when reaching the end or seeking. Non-streamed medias will namely reach the paused state right before
            // the item end notification is received. We can eliminate this pause by checking if we are at the end or not. Also update the state for
            // live streams (empty range)
            if (self.playbackState != SRGMediaPlayerPlaybackStateEnded
                     && self.playbackState != SRGMediaPlayerPlaybackStateSeeking
                     && (CMTIMERANGE_IS_EMPTY(timeRange) || CMTIME_COMPARE_INLINE(currentTime, !=, CMTimeRangeGetEnd(timeRange)))) {
                [self setPlaybackState:(player.rate == 0.f) ? SRGMediaPlayerPlaybackStatePaused : SRGMediaPlayerPlaybackStatePlaying withUserInfo:nil];
            }
            // Playback restarted after it ended (see -play and -pause)
            else if (self.playbackState == SRGMediaPlayerPlaybackStateEnded && player.rate != 0.f) {
                [self setPlaybackState:SRGMediaPlayerPlaybackStatePlaying withUserInfo:nil];
            }
        }];
        
        [player srg_addMainThreadObserver:self keyPath:@keypath(player.externalPlaybackActive) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            
#if TARGET_OS_IOS
            @strongify(player)
            
            // Pause playback when toggling off external playback with the app in background, if settings prevent playback to continue in background
            if (! player.externalPlaybackActive && self.mediaType == SRGMediaPlayerMediaTypeVideo && UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
                BOOL supportsBackgroundVideoPlayback = self.viewBackgroundBehavior == SRGMediaPlayerViewBackgroundBehaviorDetached
                    || (self.viewBackgroundBehavior == SRGMediaPlayerViewBackgroundBehaviorDetachedWhenDeviceLocked && UIDevice.srg_mediaPlayer_isLocked);
                if (! supportsBackgroundVideoPlayback) {
                    [player pause];
                }
            }
#endif
            
            [self reloadPlayerConfiguration];
            [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerExternalPlaybackStateDidChangeNotification object:self];
        }];
        
        [player srg_addMainThreadObserver:self keyPath:@keypath(player.currentItem.presentationSize) options:0 block:^(MAKVONotification * _Nonnull notification) {
            @strongify(self) @strongify(player)
            AVPlayerItem *playerItem = player.currentItem;
            self.presentationSizeValue = [NSValue valueWithCGSize:playerItem.presentationSize];
            [self updateMediaTypeForPlayerItem:playerItem];
        }];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_mediaPlayerController_playerItemDidPlayToEndTime:)
                                                   name:AVPlayerItemDidPlayToEndTimeNotification
                                                 object:player.currentItem];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_mediaPlayerController_playerItemFailedToPlayToEndTime:)
                                                   name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                 object:player.currentItem];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_mediaPlayerController_applicationDidEnterBackground:)
                                                   name:UIApplicationDidEnterBackgroundNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_mediaPlayerController_applicationWillEnterForeground:)
                                                   name:UIApplicationWillEnterForegroundNotification
                                                 object:nil];
        
        [self reloadPlayerConfiguration];
    }
}

- (void)setStallDetectionTimer:(NSTimer *)stallDetectionTimer
{
    [_stallDetectionTimer invalidate];
    _stallDetectionTimer = stallDetectionTimer;
}

- (AVPlayerLayer *)playerLayer
{
    return self.view.playerLayer;
}

- (void)setPlaybackState:(SRGMediaPlayerPlaybackState)playbackState withUserInfo:(NSDictionary *)userInfo
{
    NSAssert(NSThread.isMainThread, @"Not the main thread. Ensure important changes must be notified on the main thread. Fix");
    
    if (_playbackState == playbackState) {
        return;
    }
    
    SRGMediaPlayerPlaybackState previousPlaybackState = _playbackState;
    
    NSMutableDictionary *fullUserInfo = @{ SRGMediaPlayerPlaybackStateKey : @(playbackState),
                                           SRGMediaPlayerPreviousPlaybackStateKey: @(previousPlaybackState) }.mutableCopy;
    
    BOOL selection = self.targetSegment && ! self.targetSegment.srg_blocked;
    fullUserInfo[SRGMediaPlayerSelectionKey] = @(selection);
    if (selection) {
        fullUserInfo[SRGMediaPlayerSelectionReasonKey] = @(self.selectionReason);
    }
    if (userInfo) {
        [fullUserInfo addEntriesFromDictionary:userInfo];
    }
    
    [self willChangeValueForKey:@keypath(self.playbackState)];
    _playbackState = playbackState;
    [self didChangeValueForKey:@keypath(self.playbackState)];
    
    [self updateStallDetectionTimerForPlaybackState:playbackState];
    [self updateSegmentStatusForPlaybackState:playbackState previousPlaybackState:previousPlaybackState time:self.currentTime];
    
    [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                      object:self
                                                    userInfo:fullUserInfo.copy];
    
    SRGMediaPlayerLogDebug(@"Controller", @"Playback state did change to %@ with info %@", SRGMediaPlayerControllerNameForPlaybackState(playbackState), fullUserInfo);
}

- (void)setMediaType:(SRGMediaPlayerMediaType)mediaType
{
    if (mediaType == _mediaType) {
        return;
    }
    
    [self willChangeValueForKey:@keypath(self.mediaType)];
    _mediaType = mediaType;
    [self didChangeValueForKey:@keypath(self.mediaType)];
}

- (void)setTimeRange:(CMTimeRange)timeRange streamType:(SRGMediaPlayerStreamType)streamType live:(BOOL)live
{
    BOOL timeRangeChange = ! CMTimeRangeEqual(timeRange, _timeRange);
    BOOL streamTypeChange = (streamType != _streamType);
    BOOL liveChange = (live != _live);
    
    if (timeRangeChange) {
        [self willChangeValueForKey:@keypath(self.timeRange)];
    }
    if (streamTypeChange) {
        [self willChangeValueForKey:@keypath(self.streamType)];
    }
    if (liveChange) {
        [self willChangeValueForKey:@keypath(self.live)];
    }
    
    _timeRange = timeRange;
    _streamType = streamType;
    _live = live;
    
    if (timeRangeChange) {
        [self didChangeValueForKey:@keypath(self.timeRange)];
    }
    if (streamTypeChange) {
        [self didChangeValueForKey:@keypath(self.streamType)];
    }
    if (liveChange) {
        [self didChangeValueForKey:@keypath(self.live)];
    }
}

- (CMTimeRange)timeRange
{
    return _timeRange;
}

- (SRGMediaPlayerStreamType)streamType
{
    return _streamType;
}

- (BOOL)isLive
{
    return _live;
}

- (NSArray<id<SRGSegment>> *)segments
{
    return self.loadedSegments;
}

- (void)setSegments:(NSArray<id<SRGSegment>> *)segments
{
    self.loadedSegments = segments;
    [self updateSegmentStatusForPlaybackState:self.playbackState previousPlaybackState:self.playbackState time:self.currentTime];
}

- (void)setLoadedSegments:(NSArray<id<SRGSegment>> *)segments
{
    if (segments && self.previousSegment) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id<SRGSegment> _Nonnull segment, NSDictionary<NSString *, id> *_Nullable bindings) {
            return SRGMediaPlayerAreEqualSegments(segment, self.previousSegment);
        }];
        
        // Only update if a segment equivalent to the previous one was found (segment transition processing will update
        // the previous segment otherwise)
        id<SRGSegment> segment = [segments filteredArrayUsingPredicate:predicate].firstObject;
        if (segment) {
            self.previousSegment = segment;
        }
    }
    if (segments && self.targetSegment) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id<SRGSegment> _Nonnull segment, NSDictionary<NSString *, id> *_Nullable bindings) {
            return SRGMediaPlayerAreEqualSegments(segment, self.targetSegment);
        }];
        
        // Similar to comment above
        id<SRGSegment> segment = [segments filteredArrayUsingPredicate:predicate].firstObject;
        if (segment) {
            self.targetSegment = segment;
        }
    }
    if (segments && self.currentSegment) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id<SRGSegment> _Nonnull segment, NSDictionary<NSString *, id> *_Nullable bindings) {
            return SRGMediaPlayerAreEqualSegments(segment, self.currentSegment);
        }];
        
        // Similar to comment above
        id<SRGSegment> segment = [segments filteredArrayUsingPredicate:predicate].firstObject;
        if (segment) {
            self.currentSegment = segment;
        }
    }
    
    _loadedSegments = segments;
    
    // Reset the cached visible segment list
    _visibleSegments = nil;
}

- (NSArray<id<SRGSegment>> *)visibleSegments
{
    // Cached for faster access
    if (! _visibleSegments) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"srg_hidden == NO"];
        _visibleSegments = [self.segments filteredArrayUsingPredicate:predicate];
    }
    return _visibleSegments;
}

// Called when installing the view by binding it in a storyboard or xib
- (void)setView:(SRGMediaPlayerView *)view
{
    if (_view != view) {
        _view = view;
        [self setupView:view];
    }
}

// Called when lazily creating the view, not binding it
- (UIView *)view
{
    if (! _view) {
        _view = [[SRGMediaPlayerView alloc] init];
        [self setupView:_view];
    }
    return _view;
}

- (void)setupView:(SRGMediaPlayerView *)view
{
    view.delegate = self;
    
    if (@available(iOS 9, tvOS 14, *)) {
        @weakify(self)
        [view srg_addMainThreadObserver:self keyPath:@keypath(view.readyForDisplay) options:0 block:^(MAKVONotification * _Nonnull notification) {
            @strongify(self)
            [self updatePictureInPictureForView:view];
        }];
        [self updatePictureInPictureForView:view];
    }
    
    [self attachPlayer:self.player toView:view];
}

- (CMTimeRange)timeRangeForPlayerItem:(AVPlayerItem *)playerItem
{
    if (playerItem.status != AVPlayerStatusReadyToPlay) {
        return kCMTimeRangeInvalid;
    }
    
    NSValue *firstSeekableTimeRangeValue = playerItem.seekableTimeRanges.firstObject;
    NSValue *lastSeekableTimeRangeValue = playerItem.seekableTimeRanges.lastObject;
    
    CMTimeRange firstSeekableTimeRange = firstSeekableTimeRangeValue.CMTimeRangeValue;
    CMTimeRange lastSeekableTimeRange = lastSeekableTimeRangeValue.CMTimeRangeValue;
    
    if (! firstSeekableTimeRangeValue || CMTIMERANGE_IS_INVALID(firstSeekableTimeRange)
            || ! lastSeekableTimeRangeValue || CMTIMERANGE_IS_INVALID(lastSeekableTimeRange)) {
        return (playerItem.loadedTimeRanges.count != 0) ? kCMTimeRangeZero : kCMTimeRangeInvalid;
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

- (void)updatePlaybackInformationForPlayer:(AVPlayer *)player
{
    AVPlayerItem *playerItem = player.currentItem;
    
    [self updateMediaTypeForPlayerItem:playerItem];
    
    CMTimeRange timeRange = self.playbackInformationCached ? self.timeRange : [self timeRangeForPlayerItem:playerItem];
    SRGMediaPlayerStreamType streamType = self.playbackInformationCached ? self.streamType : [self streamTypeForPlayerItem:playerItem timeRange:timeRange];
    BOOL live = [self isLiveForPlayerItem:playerItem timeRange:timeRange streamType:streamType];
    
    [self updateReferenceForPlayerItem:playerItem timeRange:timeRange streamType:streamType];
    [self setTimeRange:timeRange streamType:streamType live:live];
    
    // On-demand time ranges are cached because they might become unreliable in some situations (e.g. when AirPlay is
    // connected or disconnected)
    if (SRG_CMTIME_IS_DEFINITE(playerItem.duration) && SRG_CMTIMERANGE_IS_NOT_EMPTY(timeRange)) {
        self.playbackInformationCached = YES;
    }
}

- (void)updateMediaTypeForPlayerItem:(AVPlayerItem *)playerItem
{
    if (self.mediaType != SRGMediaPlayerMediaTypeUnknown) {
        return;
    }
    
    // The presentation size is zero before the item is ready to play, see `presentationSize` documentation.
    if (playerItem.status != AVPlayerStatusReadyToPlay) {
        return;
    }
    
    // Cannot reliably determine the media type with AirPlay, most notably when playing a media while an AirPlay
    // connection has already been established.
    if ([AVAudioSession srg_isAirPlayActive]) {
        return;
    }
    
    NSValue *presentationSizeValue = self.presentationSizeValue;
    if (! presentationSizeValue) {
        return;
    }
    
    self.mediaType = CGSizeEqualToSize(presentationSizeValue.CGSizeValue, CGSizeZero) ? SRGMediaPlayerMediaTypeAudio : SRGMediaPlayerMediaTypeVideo;
}

- (SRGMediaPlayerStreamType)streamTypeForPlayerItem:(AVPlayerItem *)playerItem timeRange:(CMTimeRange)timeRange
{
    if (CMTIMERANGE_IS_INVALID(timeRange)) {
        return SRGMediaPlayerStreamTypeUnknown;
    }
    
    if (CMTIMERANGE_IS_EMPTY(timeRange)) {
        return SRGMediaPlayerStreamTypeLive;
    }
    else {
        CMTime duration = playerItem.duration;
        
        if (CMTIME_IS_INDEFINITE(duration)) {
            return SRGMediaPlayerStreamTypeDVR;
        }
        else if (CMTIME_COMPARE_INLINE(duration, !=, kCMTimeZero)) {
            return SRGMediaPlayerStreamTypeOnDemand;
        }
        else {
            return SRGMediaPlayerStreamTypeLive;
        }
    }
}

- (BOOL)isLiveForPlayerItem:(AVPlayerItem *)playerItem timeRange:(CMTimeRange)timeRange streamType:(SRGMediaPlayerStreamType)streamType
{
    if (streamType == SRGMediaPlayerStreamTypeLive) {
        return YES;
    }
    else if (streamType == SRGMediaPlayerStreamTypeDVR) {
        return CMTimeGetSeconds(CMTimeSubtract(CMTimeRangeGetEnd(timeRange), playerItem.currentTime)) < self.liveTolerance;
    }
    else {
        return NO;
    }
}

- (void)updateReferenceForPlayerItem:(AVPlayerItem *)playerItem timeRange:(CMTimeRange)timeRange streamType:(SRGMediaPlayerStreamType)streamType
{
    // We store synchronized current date and playhead position information for livestreams and update both regularly at the
    // same time. When seeking, these two values might namely be briefly misaligned when read from the player item directly
    // (provided the stream embedds date information, of course), leading to unreliable calculations using both values.
    //
    // If the stream does not embed date information, we use the current date as reference date, mapped to the end of
    // the DVR window. This is less accurate or might be completely incorrect, especially if stream and device clocks are
    // entirely different, but this is the best we can do.
    if (streamType == SRGMediaPlayerStreamTypeDVR || streamType == SRGMediaPlayerStreamTypeLive) {
        // Cache the date only once for stable values:
        //  - Streams without embedded timestamps: Eliminates end window oscillations because of chunks being added and removed.
        //  - Streams with embedded timestamps: Avoid discontinuities when the player is seeking.
        if (! self.referenceDate) {
            NSDate *currentDate = playerItem.currentDate;
            if (currentDate) {
                self.referenceDate = currentDate;
                self.referenceTime = playerItem.currentTime;
            }
            else {
                NSDate *referenceDate = NSDate.date;
                
                NSValue *streamOffsetValue = self.userInfo[SRGMediaPlayerUserInfoStreamOffsetKey];
                if (streamOffsetValue) {
                    CMTime streamOffset = streamOffsetValue.CMTimeValue;
                    if (CMTIME_IS_VALID(streamOffset)) {
                        CMTime positiveStreamOffset = CMTimeMaximum(streamOffset, kCMTimeZero);
                        referenceDate = [referenceDate dateByAddingTimeInterval:-CMTimeGetSeconds(positiveStreamOffset)];
                    }
                }
                
                self.referenceDate = referenceDate;
                self.referenceTime = CMTimeRangeGetEnd(timeRange);
            }
        }
    }
    else {
        self.referenceDate = nil;
        self.referenceTime = kCMTimeIndefinite;
    }
}

- (CMTime)currentTime
{
    // If `AVPlayer` is idle (e.g. right after creation), its time is zero. Use the same convention here when no
    // player is available.
    return self.player ? self.player.currentTime : kCMTimeZero;
}

- (NSDate *)currentDate
{
    return [self streamDateForTime:self.currentTime];
}

- (CMTime)seekStartTime
{
    return self.player ? self.player.seekStartTime : kCMTimeIndefinite;
}

- (CMTime)seekTargetTime
{
    return self.player ? self.player.seekTargetTime : kCMTimeIndefinite;
}

- (void)setMinimumDVRWindowLength:(NSTimeInterval)minimumDVRWindowLength
{
    if (minimumDVRWindowLength < 0.) {
        SRGMediaPlayerLogWarning(@"Controller", @"The minimum DVR window length cannot be negative. Set to 0");
        _minimumDVRWindowLength = 0.;
    }
    else {
        _minimumDVRWindowLength = minimumDVRWindowLength;
    }
}

- (void)setLiveTolerance:(NSTimeInterval)liveTolerance
{
    if (liveTolerance < 0.) {
        SRGMediaPlayerLogWarning(@"Controller", @"Live tolerance cannot be negative. Set to 0");
        _liveTolerance = 0.;
    }
    else {
        _liveTolerance = liveTolerance;
    }
}

- (void)setEndTolerance:(NSTimeInterval)endTolerance
{
    if (endTolerance < 0.) {
        SRGMediaPlayerLogWarning(@"Controller", @"End tolerance cannot be negative. Set to 0");
        _endTolerance = 0.;
    }
    else {
        _endTolerance = endTolerance;
    }
}

- (void)setEndToleranceRatio:(float)endToleranceRatio
{
    if (endToleranceRatio < 0.) {
        SRGMediaPlayerLogWarning(@"Controller", @"End tolerance ratio cannot be negative. Set to 0");
        _endToleranceRatio = 0.f;
    }
    else if (endToleranceRatio > 1.) {
        SRGMediaPlayerLogWarning(@"Controller", @"End tolerance ratio cannot be larger than 1. Set to 1");
        _endToleranceRatio = 1.f;
    }
    else {
        _endToleranceRatio = endToleranceRatio;
    }
}

- (void)setTextStyleRules:(NSArray<AVTextStyleRule *> *)textStyleRules
{
    _textStyleRules = textStyleRules.copy;
    self.player.currentItem.textStyleRules = _textStyleRules;
}

- (AVPictureInPictureController *)pictureInPictureController API_AVAILABLE(ios(9.0), tvos(14.0))
{
    if (self.playerViewController) {
        return nil;
    }
    else {
        return _pictureInPictureController;
    }
}

- (void)setPictureInPictureController:(AVPictureInPictureController *)pictureInPictureController API_AVAILABLE(ios(9.0), tvos(14.0))
{
    if (_pictureInPictureController) {
        [_pictureInPictureController removeObserver:self keyPath:@keypath(_pictureInPictureController.pictureInPicturePossible)];
        [_pictureInPictureController removeObserver:self keyPath:@keypath(_pictureInPictureController.pictureInPictureActive)];
    }
    
    _pictureInPictureController = pictureInPictureController;
    [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerPictureInPictureStateDidChangeNotification object:self];
    
    if (pictureInPictureController) {
        @weakify(self)
        [pictureInPictureController srg_addMainThreadObserver:self keyPath:@keypath(pictureInPictureController.pictureInPicturePossible) options:0 block:^(MAKVONotification * _Nonnull notification) {
            @strongify(self)
            [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerPictureInPictureStateDidChangeNotification object:self];
        }];
        [pictureInPictureController srg_addMainThreadObserver:self keyPath:@keypath(pictureInPictureController.pictureInPictureActive) options:0 block:^(MAKVONotification * _Nonnull notification) {
            @strongify(self)
            [self reloadPlayerConfiguration];
            [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerPictureInPictureStateDidChangeNotification object:self];
        }];
    }
}

- (void)updatePictureInPictureForView:(SRGMediaPlayerView *)view API_AVAILABLE(ios(9.0), tvos(14.0))
{
    AVPlayerLayer *playerLayer = view.playerLayer;
    if (playerLayer.readyForDisplay) {
        if (self.pictureInPictureController.playerLayer != playerLayer) {
            self.pictureInPictureController = [[AVPictureInPictureController alloc] initWithPlayerLayer:playerLayer];
            self.pictureInPictureControllerCreationBlock ? self.pictureInPictureControllerCreationBlock(self.pictureInPictureController) : nil;
        }
    }
    else {
        self.pictureInPictureController = nil;
    }
}

- (BOOL)allowsExternalNonMirroredPlayback
{
    AVPlayer *player = self.player;
    if (! player) {
        return NO;
    }
    
    if (! player.allowsExternalPlayback) {
        return NO;
    }
    
    if (! UIScreen.srg_isMirroring) {
        return YES;
    }
    
    // If the player switches to external playback, then it does not mirror the display
    return player.usesExternalPlaybackWhileExternalScreenIsActive;
}

- (BOOL)isExternalNonMirroredPlaybackActive
{
    if (! AVAudioSession.srg_isAirPlayActive) {
        return NO;
    }
    
    AVPlayer *player = self.player;
    if (! player) {
        return NO;
    }
    
    // We do not test the `externalPlaybackActive` property here, on purpose: The fact that AirPlay is active was
    // tested just above, and the `externalPlaybackActive` property is less reliable in some cases where AirPlay
    // settings are changed, but AirPlay is still active
    if (! player.allowsExternalPlayback) {
        return NO;
    }
    
    if (! UIScreen.srg_isMirroring) {
        return player.externalPlaybackActive;
    }
    
    // If the player switches to external playback, then it does not mirror the display
    return player.usesExternalPlaybackWhileExternalScreenIsActive;
}

#pragma mark Picture in picture

// TODO: Remove once tvOS 14 is the minimum version
- (BOOL)isPictureInPictureActive
{
    if (@available(iOS 9, tvOS 14, *)) {
        return self.pictureInPictureController.pictureInPictureActive;
    }
    else {
        return NO;
    }
}

// TODO: Remove once tvOS 14 is the minimum version
- (void)stopPictureInPicture
{
    if (@available(iOS 9, tvOS 14, *)) {
        [self.pictureInPictureController stopPictureInPicture];
    }
}

#pragma mark Conversions

- (CMTime)streamTimeForMark:(SRGMark *)mark withTimeOrigin:(CMTime)time
{
    if (mark.date) {
        return [self streamTimeForDate:mark.date];
    }
    else {
        CMTime relativeTime = [mark timeForMediaPlayerController:nil];
        return CMTimeAdd(time, relativeTime);
    }
}

- (CMTimeRange)streamTimeRangeForMarkRange:(SRGMarkRange *)markRange
{
    CMTime fromTime = [self streamTimeForMark:markRange.fromMark withTimeOrigin:kCMTimeZero];
    CMTime toTime = [self streamTimeForMark:markRange.toMark withTimeOrigin:kCMTimeZero];
    return CMTimeRangeFromTimeToTime(fromTime, toTime);
}

- (CMTime)streamTimeForDate:(NSDate *)date
{
    if (date && self.referenceDate) {
        NSTimeInterval offset = [date timeIntervalSinceDate:self.referenceDate];
        return CMTimeAdd(self.referenceTime, CMTimeMakeWithSeconds(offset, NSEC_PER_SEC));
    }
    else {
        return kCMTimeZero;
    }
}

- (NSDate *)streamDateForTime:(CMTime)time
{
    if (self.referenceDate) {
        NSTimeInterval offset = CMTimeGetSeconds(CMTimeSubtract(time, self.referenceTime));
        return [self.referenceDate dateByAddingTimeInterval:offset];
    }
    else {
        return nil;
    }
}

- (SRGTimePosition *)timePositionForPosition:(SRGPosition *)position inSegment:(id<SRGSegment>)segment applyEndTolerance:(BOOL)applyEndTolerance
{
    if (! segment) {
        // Always relative to a fixed zero origin (NOT to the stream time range start, which moves for a sliding DVR window).
        CMTime time = [self streamTimeForMark:position.mark withTimeOrigin:kCMTimeZero];
        
        // Default position
        if (CMTIME_COMPARE_INLINE(time, ==, kCMTimeZero)) {
            return SRGTimePosition.defaultPosition;
        }
        else {
            // Return the default position if the desired position is above tolerance settings.
            CMTimeRange timeRange = self.timeRange;
            
            if (applyEndTolerance) {
                CMTime tolerance = SRGMediaPlayerEffectiveEndTolerance(self.endTolerance, self.endToleranceRatio, CMTimeGetSeconds(timeRange.duration));
                if (CMTIME_COMPARE_INLINE(time, >=, CMTimeSubtract(timeRange.duration, tolerance))) {
                    return SRGTimePosition.defaultPosition;
                }
            }
            
            // Fit position settings to the available time range (cut a bit off at the end to ensure we do not fall outside
            // the seekable range).
            SRGTimePosition *timePosition = [SRGTimePosition positionWithTime:time toleranceBefore:position.toleranceBefore toleranceAfter:position.toleranceAfter];
            return SRGMediaPlayerControllerPositionInTimeRange(timePosition, timeRange, kCMTimeZero, SRGSafeSeekOffset());
        }
    }
    else {
        // Convert to a time in the stream reference frame.
        CMTimeRange segmentTimeRange = [self streamTimeRangeForMarkRange:segment.srg_markRange];
        CMTime time = [self streamTimeForMark:position.mark withTimeOrigin:segmentTimeRange.start];
        
        // Return the beginning if the desired position is above tolerance settings.
        if (applyEndTolerance) {
            CMTime tolerance = SRGMediaPlayerEffectiveEndTolerance(self.endTolerance, self.endToleranceRatio, CMTimeGetSeconds(segmentTimeRange.duration));
            if (CMTIME_COMPARE_INLINE(time, >=, CMTimeSubtract(CMTimeRangeGetEnd(segmentTimeRange), tolerance))) {
                time = segmentTimeRange.start;
            }
        }
        
        // Fit position settings to the restricted segment time range. Cut a bit off of the segment at start ends to ensure
        // playback takes place within the segment (segment start requires a different to compensate Bluetooth seek imprecisions).
        SRGTimePosition *timePosition = [SRGTimePosition positionWithTime:time toleranceBefore:position.toleranceBefore toleranceAfter:position.toleranceAfter];
        timePosition = SRGMediaPlayerControllerPositionInTimeRange(timePosition, segmentTimeRange, SRGSafeStartSeekOffset(), SRGSafeSeekOffset());
        
        // Fit position settings to the available time range (cut a bit off at the end to ensure we do not fall outside
        // the seekable range).
        return SRGMediaPlayerControllerPositionInTimeRange(timePosition, self.timeRange, kCMTimeZero, SRGSafeSeekOffset());
    }
}

#pragma mark Playback

- (void)prepareToPlayURL:(NSURL *)URL
              atPosition:(SRGPosition *)position
            withSegments:(NSArray<id<SRGSegment>> *)segments
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURLAsset:nil URL:URL atPosition:position withSegments:segments targetSegment:nil userInfo:userInfo completionHandler:completionHandler];
}

- (void)prepareToPlayURLAsset:(AVURLAsset *)URLAsset
                   atPosition:(SRGPosition *)position
                 withSegments:(NSArray<id<SRGSegment>> *)segments
                     userInfo:(NSDictionary *)userInfo
            completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURLAsset:URLAsset URL:nil atPosition:position withSegments:segments targetSegment:nil userInfo:userInfo completionHandler:completionHandler];
}

- (void)play
{
    // Player is available
    if (self.player) {
        // Normal conditions. Simply forward to the player
        if (self.playbackState != SRGMediaPlayerPlaybackStateEnded) {
            [self.player playImmediatelyIfPossible];
        }
        // Playback ended. Restart at the beginning
        else {
            [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero notify:NO completionHandler:^(BOOL finished) {
                if (finished) {
                    [self.player playImmediatelyIfPossible];
                }
            }];
        }
    }
    // Player has been removed (e.g. after a -stop). Restart playback with the same conditions (if not cleared)
    else if (self.contentURL) {
        [self prepareToPlayURLAsset:nil URL:self.contentURL atPosition:self.initialPosition withSegments:self.segments targetSegment:self.initialTargetSegment userInfo:self.userInfo completionHandler:^{
            [self play];
        }];
    }
    else if (self.URLAsset) {
        [self prepareToPlayURLAsset:self.URLAsset.copy URL:nil atPosition:self.initialPosition withSegments:self.segments targetSegment:self.initialTargetSegment userInfo:self.userInfo completionHandler:^{
            [self play];
        }];
    }
}

- (void)pause
{
    // Won't do anything if called after playback has ended
    [self.player pause];
}

- (void)stop
{
    [self stopWithUserInfo:nil];
}

- (void)seekToPosition:(SRGPosition *)position withCompletionHandler:(void (^)(BOOL))completionHandler
{
    [self seekToPosition:position inTargetSegment:nil completionHandler:completionHandler];
}

- (void)reset
{
    // Save previous state information
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (self.contentURL) {
        userInfo[SRGMediaPlayerPreviousContentURLKey] = self.contentURL;
    }
    if (self.URLAsset) {
        userInfo[SRGMediaPlayerPreviousURLAssetKey] = self.URLAsset;
    }
    if (self.userInfo) {
        userInfo[SRGMediaPlayerPreviousUserInfoKey] = self.userInfo;
    }
    
    // Reset input values (so that any state change notification reflects this new state)
    self.contentURL = nil;
    self.URLAsset = nil;
    self.loadedSegments = nil;
    self.userInfo = nil;
    
    self.initialTargetSegment = nil;
    self.initialPosition = nil;
    
    [self stopWithUserInfo:userInfo.copy];
}

#pragma mark Playback (convenience methods)

- (void)prepareToPlayURL:(NSURL *)URL withCompletionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURL:URL atPosition:nil withSegments:nil userInfo:nil completionHandler:completionHandler];
}

- (void)prepareToPlayURLAsset:(AVURLAsset *)URLAsset withCompletionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURLAsset:URLAsset atPosition:nil withSegments:nil userInfo:nil completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL atPosition:(SRGPosition *)position withSegments:(NSArray<id<SRGSegment>> *)segments userInfo:(NSDictionary *)userInfo
{
    [self prepareToPlayURL:URL atPosition:position withSegments:segments userInfo:userInfo completionHandler:^{
        [self play];
    }];
}

- (void)playURLAsset:(AVURLAsset *)URLAsset atPosition:(SRGPosition *)position withSegments:(NSArray<id<SRGSegment>> *)segments userInfo:(NSDictionary *)userInfo
{
    [self prepareToPlayURLAsset:URLAsset atPosition:position withSegments:segments userInfo:userInfo completionHandler:^{
        [self play];
    }];
}

- (void)playURL:(NSURL *)URL
{
    [self playURL:URL atPosition:nil withSegments:nil userInfo:nil];
}

- (void)playURLAsset:(AVURLAsset *)URLAsset
{
    [self playURLAsset:URLAsset atPosition:nil withSegments:nil userInfo:nil];
}

- (void)togglePlayPause
{
    if (self.player && self.player.rate == 1.f) {
        [self pause];
    }
    else {
        [self play];
    }
}

#pragma mark Segment playback

- (void)prepareToPlayURL:(NSURL *)URL
                 atIndex:(NSInteger)index
                position:(SRGPosition *)position
              inSegments:(NSArray<id<SRGSegment>> *)segments
            withUserInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    id<SRGSegment> targetSegment = (index >= 0 && index < segments.count) ? segments[index] : nil;
    [self prepareToPlayURLAsset:nil URL:URL atPosition:position withSegments:segments targetSegment:targetSegment userInfo:userInfo completionHandler:completionHandler];
}

- (void)prepareToPlayURLAsset:(AVURLAsset *)URLAsset
                      atIndex:(NSInteger)index
                     position:(SRGPosition *)position
                   inSegments:(NSArray<id<SRGSegment>> *)segments
                 withUserInfo:(NSDictionary *)userInfo
            completionHandler:(void (^)(void))completionHandler
{
    id<SRGSegment> targetSegment = (index >= 0 && index < segments.count) ? segments[index] : nil;
    [self prepareToPlayURLAsset:URLAsset URL:nil atPosition:position withSegments:segments targetSegment:targetSegment userInfo:userInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
        atIndex:(NSInteger)index
       position:(SRGPosition *)position
     inSegments:(NSArray<id<SRGSegment>> *)segments
   withUserInfo:(NSDictionary *)userInfo
{
    [self prepareToPlayURL:URL atIndex:index position:position inSegments:segments withUserInfo:userInfo completionHandler:^{
        [self play];
    }];
}

- (void)playURLAsset:(AVURLAsset *)URLAsset
             atIndex:(NSInteger)index
            position:(SRGPosition *)position
          inSegments:(NSArray<id<SRGSegment>> *)segments
        withUserInfo:(NSDictionary *)userInfo
{
    [self prepareToPlayURLAsset:URLAsset atIndex:index position:position inSegments:segments withUserInfo:userInfo completionHandler:^{
        [self play];
    }];
}

- (void)seekToPosition:(SRGPosition *)position inSegmentAtIndex:(NSInteger)index withCompletionHandler:(void (^)(BOOL))completionHandler
{
    if (index < 0 || index >= self.segments.count) {
        return;
    }
    
    [self seekToPosition:position inSegment:self.segments[index] withCompletionHandler:completionHandler];
}

- (void)seekToPosition:(SRGPosition *)position inSegment:(id<SRGSegment>)segment withCompletionHandler:(void (^)(BOOL))completionHandler
{
    if (! [self.segments containsObject:segment]) {
        return;
    }
    
    [self seekToPosition:position inTargetSegment:segment completionHandler:completionHandler];
}

- (id<SRGSegment>)selectedSegment
{
    return _selected ? self.currentSegment : nil;
}

#pragma mark Playback (internal). Time parameters are ignored when valid segments are provided

- (void)prepareToPlayURLAsset:(AVURLAsset *)URLAsset
                          URL:(NSURL *)URL
                   atPosition:(SRGPosition *)position
                 withSegments:(NSArray<id<SRGSegment>> *)segments
                targetSegment:(id<SRGSegment>)targetSegment
                     userInfo:(NSDictionary *)userInfo
            completionHandler:(void (^)(void))completionHandler
{
    NSAssert(URLAsset || URL, @"A URL asset or URL must be provided");
    NSAssert(! targetSegment || [segments containsObject:targetSegment], @"Segment must be valid");
    
    if (! position) {
        position = SRGPosition.defaultPosition;
    }
    
    if (URLAsset) {
        URL = URLAsset.URL;
    }
    else {
        URLAsset = [AVURLAsset assetWithURL:URL];
    }
    
    SRGMediaPlayerLogDebug(@"Controller", @"Playing %@", URL);
    
    [self reset];
    
    self.contentURL = URL;
    self.URLAsset = URLAsset;
    
    self.loadedSegments = segments;
    self.userInfo = userInfo;
    
    self.targetSegment = targetSegment;
    self.selectionReason = SRGMediaPlayerSelectionReasonInitial;
    
    // Save initial values for restart after a stop
    self.initialTargetSegment = targetSegment;
    self.initialPosition = position;
    
    // Values used at startup and nilled afterwards
    self.startPosition = position;
    self.startCompletionHandler = completionHandler;
    
    // Hide the view until playback starts to avoid briefly displaying the frame which the player was loaded into first
    // (default playback position). Hide the internal view since visibility of the media player view can be controlled
    // by clients.
    self.view.playbackViewHidden = YES;
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:URLAsset];
    playerItem.textStyleRules = self.textStyleRules;
    
    self.player = [SRGPlayer playerWithPlayerItem:playerItem];
    self.player.delegate = self;
    
    @weakify(self)
    [URLAsset loadValuesAsynchronouslyForKeys:@[ @keypath(URLAsset.availableMediaCharacteristicsWithMediaSelectionOptions) ] completionHandler:^{
        @strongify(self)
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadMediaConfiguration];
        });
    }];
    
    // Notify the state change last. If clients repond to the preparing state change notification, the state need to
    // be fully consistent first.
    [self setPlaybackState:SRGMediaPlayerPlaybackStatePreparing withUserInfo:nil];
}

- (void)seekToPosition:(SRGPosition *)position inTargetSegment:(id<SRGSegment>)targetSegment completionHandler:(void (^)(BOOL))completionHandler
{
    NSAssert(! targetSegment || [self.segments containsObject:targetSegment], @"Segment must be valid");
    
    if (self.player.currentItem.status != AVPlayerItemStatusReadyToPlay) {
        return;
    }
    
    if (self.streamType == SRGMediaPlayerStreamTypeLive) {
        return;
    }
    
    self.targetSegment = targetSegment;
    self.selectionReason = SRGMediaPlayerSelectionReasonUpdate;
    
    SRGTimePosition *timePosition = [self timePositionForPosition:position inSegment:targetSegment applyEndTolerance:NO];
    
    // Trap attempts to seek to blocked segments early. We cannot only rely on playback time observers to detect a blocked segment
    // for direct seeks, otherwise blocked segment detection would occur after the segment has been entered, which is too late
    id<SRGSegment> segment = targetSegment ?: [self segmentForTime:timePosition.time];
    if (! segment || ! segment.srg_blocked) {
        // Starting with iOS 11, there is no guarantee that the last seek succeeds (there was no formal documentation for this
        // behavior on iOS 10 and below, but this was generally working). Starting with iOS 11, the following is unreliable,
        // as the state might not be updated if the last seek gets cancelled. This is especially the case if multiple seeks
        // are made in sequence (with some small delay between them), the last seek occuring at the end of the stream.
        //
        // To be able to reset the state no matter the last seek finished, we use a special category method which keeps count
        // of the count of seek requests still pending.
        [self.player seekToTime:timePosition.time toleranceBefore:timePosition.toleranceBefore toleranceAfter:timePosition.toleranceAfter notify:YES completionHandler:^(BOOL finished) {
            completionHandler ? completionHandler(finished) : nil;
        }];
    }
    else {
        [self skipBlockedSegment:segment withCompletionHandler:completionHandler];
    }
}

- (void)stopWithUserInfo:(NSDictionary *)userInfo
{
    if ([self isPictureInPictureActive]) {
        [self stopPictureInPicture];
    }
    
    NSMutableDictionary *fullUserInfo = userInfo.mutableCopy ?: [NSMutableDictionary dictionary];
    
    // Only reset if needed (this would otherwise lazily instantiate the view again and create potential issues)
    if (self.player) {
        [self.player.currentItem.asset cancelLoading];
        
        CMTime lastPlaybackTime = self.player.currentTime;
        fullUserInfo[SRGMediaPlayerLastPlaybackTimeKey] = [NSValue valueWithCMTime:lastPlaybackTime];
        fullUserInfo[SRGMediaPlayerLastPlaybackDateKey] = [self streamDateForTime:lastPlaybackTime];
        fullUserInfo[SRGMediaPlayerPreviousTimeRangeKey] = [NSValue valueWithCMTimeRange:self.timeRange];
        fullUserInfo[SRGMediaPlayerPreviousMediaTypeKey] = @(self.mediaType);
        fullUserInfo[SRGMediaPlayerPreviousStreamTypeKey] = @(self.streamType);
        if (_selected) {
            fullUserInfo[SRGMediaPlayerPreviousSelectedSegmentKey] = self.currentSegment;
        }
        self.player = nil;
    }
    
    _selected = NO;
    
    self.mediaType = SRGMediaPlayerMediaTypeUnknown;
    
    self.referenceTime = kCMTimeIndefinite;
    self.referenceDate = nil;
    
    [self setTimeRange:kCMTimeRangeInvalid streamType:SRGMediaPlayerStreamTypeUnknown live:NO];
    
    self.playbackInformationCached = NO;
    
    self.previousSegment = nil;
    self.currentSegment = nil;
    self.targetSegment = nil;
    
    self.startPosition = nil;
    self.startCompletionHandler = nil;
    
    self.presentationSizeValue = nil;
    
    self.lastPlaybackTime = kCMTimeIndefinite;
    self.lastStallDetectionDate = nil;
    
    [self updateTracksForPlayer:nil];
    
    if (@available(iOS 9, tvOS 14, *)) {
        self.pictureInPictureController = nil;
    }
    self.savedAllowsExternalPlayback = nil;
    
    if (@available(iOS 12, tvOS 12, *)) {
        self.savedPreventsDisplaySleepDuringVideoPlayback = nil;
    }
    
    // Emit the notification once all state has been reset
    [self setPlaybackState:SRGMediaPlayerPlaybackStateIdle withUserInfo:fullUserInfo.copy];
}

#pragma mark Configuration

- (void)reloadPlayerConfiguration
{
    if (self.player) {
        if (! [self isPictureInPictureActive] && self.savedAllowsExternalPlayback) {
            self.player.allowsExternalPlayback = self.savedAllowsExternalPlayback.boolValue;
            self.savedAllowsExternalPlayback = nil;
        }
        
        if (@available(iOS 12, tvOS 12, *)) {
            if (self.savedPreventsDisplaySleepDuringVideoPlayback) {
                self.player.preventsDisplaySleepDuringVideoPlayback = self.savedPreventsDisplaySleepDuringVideoPlayback.boolValue;
                self.savedPreventsDisplaySleepDuringVideoPlayback = nil;
            }
        }
        
        self.playerConfigurationBlock ? self.playerConfigurationBlock(self.player) : nil;
        
        // If picture in picture is active, it is difficult to return from PiP if enabling AirPlay from the control
        // center (this would require calling the restoration methods, not called natively in this case, to let the app
        // restore the playback UI so that AirPlay playback can resume there). Sadly such attempts leave the player layer
        // in a mixed state, still displaying the PiP icon.
        //
        // The inverse approach is far easier: When PiP is enabled, we override player settings to prevent external playback,
        // restoring them afterwards.
        if ([self isPictureInPictureActive]) {
            self.savedAllowsExternalPlayback = @(self.player.allowsExternalPlayback);
            self.player.allowsExternalPlayback = NO;
        }
        
        if (@available(iOS 12, tvOS 12, *)) {
            if (! self.playerViewController) {
                if ([self isPictureInPictureActive]) {
                    self.savedPreventsDisplaySleepDuringVideoPlayback = @(self.player.preventsDisplaySleepDuringVideoPlayback);
                    self.player.preventsDisplaySleepDuringVideoPlayback = YES;
                }
                else if (self.player.externalPlaybackActive) {
                    self.savedPreventsDisplaySleepDuringVideoPlayback = @(self.player.preventsDisplaySleepDuringVideoPlayback);
                    self.player.preventsDisplaySleepDuringVideoPlayback = NO;
                }
                else if (! self.view.player || ! self.view.window) {
                    self.savedPreventsDisplaySleepDuringVideoPlayback = @(self.player.preventsDisplaySleepDuringVideoPlayback);
                    self.player.preventsDisplaySleepDuringVideoPlayback = NO;
                }
            }
        }
    }
}

- (void)reloadMediaConfiguration
{
    AVPlayerItem *playerItem = self.player.currentItem;
    AVAsset *asset = playerItem.asset;
    
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] != AVKeyValueStatusLoaded) {
        return;
    }
    
    AVMediaSelectionOption *audioOption = nil;
    
    // Setup audio. A return value is mandatory in the block signature (if setting `nil` as audio option, no option is
    // selected but audio is played anyway, so making the return value optional would be misleading).
    AVMediaSelectionGroup *audioGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    if (audioGroup) {
        NSArray<AVMediaSelectionOption *> *audioOptions = audioGroup.options;
        AVMediaSelectionOption *defaultAudioOption = SRGMediaPlayerControllerAutomaticAudioDefaultOption(audioOptions);
        if (self.audioConfigurationBlock) {
            audioOption = self.audioConfigurationBlock(audioOptions, defaultAudioOption);
            
            // Gracely handle implementation errors. Though the block signature should be followed, compilers might not be able
            // to catch `nil` return values. Instead of leading to errors discovered only later in production, assert for
            // discovery during development, and use the default as fallback to avoid problems if this is discovered after
            // a release has been made.
            if (! audioOption) {
                NSAssert(NO, @"Missing audio option returned from an audio configuration block. Return the supplied default option instead.");
                audioOption = defaultAudioOption;
            }
        }
        else {
            audioOption = defaultAudioOption;
        }
        [playerItem selectMediaOption:audioOption inMediaSelectionGroup:audioGroup];
    }
    
    // Setup subtitles. The value `nil` is allowed to disable subtitles entirely.
    AVMediaSelectionGroup *subtitleGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    if (subtitleGroup) {
        NSArray<AVMediaSelectionOption *> *subtitleOptions = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:subtitleGroup.srgmediaplayer_languageOptions withoutMediaCharacteristics:@[AVMediaCharacteristicContainsOnlyForcedSubtitles]];
        AVMediaSelectionOption *defaultSubtitleOption = SRGMediaPlayerControllerSubtitleDefaultOption(subtitleOptions, audioOption);
        AVMediaSelectionOption *subtitleOption = self.subtitleConfigurationBlock ? self.subtitleConfigurationBlock(subtitleOptions, audioOption, defaultSubtitleOption) : defaultSubtitleOption;
        [playerItem selectMediaOption:subtitleOption inMediaSelectionGroup:subtitleGroup];
    }
    
    [self updateTracksForPlayer:self.player];
}

#pragma mark Stall detection

- (void)updateStallDetectionTimerForPlaybackState:(SRGMediaPlayerPlaybackState)playbackState
{
    if (playbackState == SRGMediaPlayerPlaybackStatePlaying) {
        @weakify(self)
        self.stallDetectionTimer = [NSTimer srgmediaplayer_timerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            
            AVPlayerItem *playerItem = self.player.currentItem;
            CMTime currentTime = playerItem.currentTime;
            
            if (self.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
                // Playing but playhead position not actually moving. Stalled
                if (CMTIME_COMPARE_INLINE(self.lastPlaybackTime, ==, currentTime)) {
                    [self setPlaybackState:SRGMediaPlayerPlaybackStateStalled withUserInfo:nil];
                    self.lastStallDetectionDate = NSDate.date;
                }
                else {
                    self.lastPlaybackTime = currentTime;
                }
            }
            else if (self.playbackState == SRGMediaPlayerPlaybackStateStalled) {
                // Stalled but we detect the playhead position has moved. Not stalled anymore
                if (CMTIME_COMPARE_INLINE(self.lastPlaybackTime, !=, currentTime)) {
                    [self setPlaybackState:SRGMediaPlayerPlaybackStatePlaying withUserInfo:nil];
                    self.lastStallDetectionDate = nil;
                }
                else if ([NSDate.date timeIntervalSinceDate:self.lastStallDetectionDate] >= 5.) {
                    [self.player playImmediatelyIfPossible];
                }
            }
        }];
    }
    else if (playbackState != SRGMediaPlayerPlaybackStateStalled) {
        self.stallDetectionTimer = nil;
    }
}

#pragma mark Segments

- (void)updateSegmentStatusForPlaybackState:(SRGMediaPlayerPlaybackState)playbackState
                      previousPlaybackState:(SRGMediaPlayerPlaybackState)previousPlaybackState
                                       time:(CMTime)time
{
    if (CMTIME_IS_INVALID(time)) {
        return;
    }
    
    // Only update when relevant
    if (playbackState != SRGMediaPlayerPlaybackStatePaused && playbackState != SRGMediaPlayerPlaybackStatePlaying
            && playbackState != SRGMediaPlayerPlaybackStateEnded) {
        return;
    }
    
    if (self.targetSegment) {
        [self processTransitionToSegment:self.targetSegment selected:YES interrupted:YES];
        self.targetSegment = nil;
    }
    else {
        id<SRGSegment> segment = [self segmentForTime:time];
        BOOL interrupted = (previousPlaybackState == SRGMediaPlayerPlaybackStateSeeking);
        [self processTransitionToSegment:segment selected:NO interrupted:interrupted];
    }
}

// Emit correct notifications for transitions (selected = NO for normal playback, YES if the segment has been selected)
// and seek over blocked segments. interrupted is set to NO if playback
- (void)processTransitionToSegment:(id<SRGSegment>)segment selected:(BOOL)selected interrupted:(BOOL)interrupted
{
    // No segment transition. Nothing to do
    if (segment == self.previousSegment && ! selected) {
        return;
    }
    
    CMTime lastPlaybackTime = CMTIME_IS_INDEFINITE(self.seekStartTime) ? self.currentTime : self.seekStartTime;
    NSDate *lastPlaybackDate = [self streamDateForTime:lastPlaybackTime];
    
    if (self.previousSegment && ! self.previousSegment.srg_blocked) {
        self.currentSegment = nil;
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[SRGMediaPlayerSegmentKey] = self.previousSegment;
        userInfo[SRGMediaPlayerSelectionKey] = @(selected);
        if (selected) {
            userInfo[SRGMediaPlayerSelectionReasonKey] = @(self.selectionReason);
        }
        userInfo[SRGMediaPlayerSelectedKey] = @(_selected);
        userInfo[SRGMediaPlayerInterruptionKey] = @(interrupted);
        userInfo[SRGMediaPlayerLastPlaybackTimeKey] = [NSValue valueWithCMTime:lastPlaybackTime];
        userInfo[SRGMediaPlayerLastPlaybackDateKey] = lastPlaybackDate;
        
        if (! segment.srg_blocked) {
            userInfo[SRGMediaPlayerNextSegmentKey] = segment;
        }

        [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerSegmentDidEndNotification
                                                          object:self
                                                        userInfo:userInfo.copy];
        _selected = NO;
        
        SRGMediaPlayerLogDebug(@"Controller", @"Segment did end with info %@", userInfo);
    }
    
    if (segment) {
        if (! segment.srg_blocked) {
            _selected = selected;
            
            self.currentSegment = segment;
            
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            userInfo[SRGMediaPlayerSegmentKey] = segment;
            userInfo[SRGMediaPlayerSelectionKey] = @(_selected);
            if (_selected) {
                userInfo[SRGMediaPlayerSelectionReasonKey] = @(self.selectionReason);
            }
            userInfo[SRGMediaPlayerSelectedKey] = @(_selected);
            userInfo[SRGMediaPlayerLastPlaybackTimeKey] = [NSValue valueWithCMTime:lastPlaybackTime];
            userInfo[SRGMediaPlayerLastPlaybackDateKey] = lastPlaybackDate;
            
            if (self.previousSegment && ! self.previousSegment.srg_blocked) {
                userInfo[SRGMediaPlayerPreviousSegmentKey] = self.previousSegment;
            }
            
            [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerSegmentDidStartNotification
                                                              object:self
                                                            userInfo:userInfo.copy];
            
            SRGMediaPlayerLogDebug(@"Controller", @"Segment did start with info %@", userInfo);
        }
        else {
            [self skipBlockedSegment:segment withCompletionHandler:nil];
        }
    }
    
    self.previousSegment = segment;
}

- (id<SRGSegment>)segmentForTime:(CMTime)time
{
    if (CMTIME_IS_INVALID(time)) {
        return nil;
    }
    
    __block id<SRGSegment> locatedSegment = nil;
    [self.segments enumerateObjectsUsingBlock:^(id<SRGSegment>  _Nonnull segment, NSUInteger idx, BOOL * _Nonnull stop) {
        CMTimeRange segmentTimeRange = [self streamTimeRangeForMarkRange:segment.srg_markRange];
        if (CMTimeRangeContainsTime(segmentTimeRange, time)) {
            locatedSegment = segment;
            *stop = YES;
        }
    }];
    return locatedSegment;
}

// No tolerance parameters here. When skipping blocked segments, we want to resume sharply at segment end
- (void)skipBlockedSegment:(id<SRGSegment>)segment withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    NSAssert(segment.srg_blocked, @"Expect a blocked segment");
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[SRGMediaPlayerSegmentKey] = segment;
    
    CMTime currentTime = self.currentTime;
    userInfo[SRGMediaPlayerLastPlaybackTimeKey] = [NSValue valueWithCMTime:currentTime];
    userInfo[SRGMediaPlayerLastPlaybackDateKey] = [self streamDateForTime:currentTime];
    
    [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerWillSkipBlockedSegmentNotification
                                                      object:self
                                                    userInfo:userInfo.copy];
    
    SRGMediaPlayerLogDebug(@"Controller", @"Segment %@ will be skipped", segment);
    
    // Seek precisely just after the end of the segment to avoid reentering the blocked segment when playback resumes (which
    // would trigger skips recursively)
    CMTimeRange segmentTimeRange = [self streamTimeRangeForMarkRange:segment.srg_markRange];
    CMTime seekTime = CMTimeAdd(CMTimeRangeGetEnd(segmentTimeRange), SRGSafeStartSeekOffset());
    SRGPosition *seekTimePosition = [SRGPosition positionAtTime:seekTime];
    [self seekToPosition:seekTimePosition withCompletionHandler:^(BOOL finished) {
        // Do not check the finished boolean. We want to emit the notification even if the seek is interrupted by another
        // one (e.g. due to a contiguous blocked segment being skipped). Emit the notification after the completion handler
        // so that consecutive notifications are received in the correct order
        [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerDidSkipBlockedSegmentNotification
                                                          object:self
                                                        userInfo:userInfo.copy];
        
        SRGMediaPlayerLogDebug(@"Controller", @"Segment %@ was skipped", segment);
        
        completionHandler ? completionHandler(finished) : nil;
    }];
}

#pragma mark AVPlayerViewController support

- (void)bindToPlayerViewController:(AVPlayerViewController *)playerViewController
{
    if (self.playerViewController) {
        self.playerViewController.player = nil;
    }
    
    playerViewController.player = self.player;
    self.playerViewController = playerViewController;
    
    // AVPlayerViewController works well (e.g. playback won't freeze in the simulator after a few seconds) only if
    // the attached player is not bound to any other layer. We therefore detach the player from the controller view.
    self.view.player = nil;
}

- (void)unbindFromCurrentPlayerViewController
{
    if (! self.playerViewController) {
        return;
    }
    
    self.playerViewController.player = nil;
    self.playerViewController = nil;
    
    // Rebind the player
    self.view.player = self.player;
}

- (void)attachPlayer:(AVPlayer *)player toView:(SRGMediaPlayerView *)view
{
    if (self.playerViewController) {
        self.playerViewController.player = player;
    }
    else {
        view.player = player;
    }
}

#pragma mark Tracks

- (AVMediaSelectionOption *)selectedOptionForPlayer:(AVPlayer *)player withMediaCharacteristic:(AVMediaCharacteristic)mediaCharacteristic
{
    AVPlayerItem *playerItem = player.currentItem;
    AVAsset *asset = playerItem.asset;
    
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] != AVKeyValueStatusLoaded) {
        return nil;
    }
    
    AVMediaSelectionGroup *audioGroup = [asset mediaSelectionGroupForMediaCharacteristic:mediaCharacteristic];
    return audioGroup ? [playerItem srgmediaplayer_selectedMediaOptionInMediaSelectionGroup:audioGroup] : nil;
}

- (void)updateTracksForPlayer:(AVPlayer *)player
{
    NSAssert(NSThread.isMainThread, @"Expected to be called on the main thread");
    
    AVMediaSelectionOption *audioOption = [self selectedOptionForPlayer:player withMediaCharacteristic:AVMediaCharacteristicAudible];
    if (audioOption != self.audioOption && ! [audioOption isEqual:self.audioOption]) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        if (self.audioOption) {
            userInfo[SRGMediaPlayerPreviousTrackKey] = self.audioOption;
        }
        if (audioOption) {
            userInfo[SRGMediaPlayerTrackKey] = audioOption;
        }
        
        self.audioOption = audioOption;
        
        [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerAudioTrackDidChangeNotification
                                                          object:self
                                                        userInfo:userInfo.copy];
    }
    
    AVMediaSelectionOption *subtitleOption = [self selectedOptionForPlayer:player withMediaCharacteristic:AVMediaCharacteristicLegible];
    if (subtitleOption != self.subtitleOption && ! [subtitleOption isEqual:self.subtitleOption]) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        if (self.subtitleOption) {
            userInfo[SRGMediaPlayerPreviousTrackKey] = self.subtitleOption;
        }
        if (subtitleOption) {
            userInfo[SRGMediaPlayerTrackKey] = subtitleOption;
        }
        
        self.subtitleOption = subtitleOption;
        
        [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerSubtitleTrackDidChangeNotification
                                                          object:self
                                                        userInfo:userInfo.copy];
    }
}

- (void)selectMediaOption:(AVMediaSelectionOption *)option inMediaSelectionGroupWithCharacteristic:(AVMediaCharacteristic)characteristic
{
    AVPlayerItem *playerItem = self.player.currentItem;
    AVAsset *asset = playerItem.asset;
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] != AVKeyValueStatusLoaded) {
        return;
    }
    
    AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:characteristic];
    if (! group) {
        return;
    }
    
    [playerItem selectMediaOption:option inMediaSelectionGroup:group];
    
    // If Automatic has been set for subtitles, changing the audio must update the subtitles accordingly
    MACaptionAppearanceDisplayType displayType = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
    if ([characteristic isEqualToString:AVMediaCharacteristicAudible] && displayType == kMACaptionAppearanceDisplayTypeAutomatic) {
        // Provide the selected audio option as context information, so that update is consistent when using AirPlay as well
        // (we cannot use `-selectMediaOptionAutomaticallyInMediaSelectionGroupWithCharacteristic:`) as the audio selection
        // takes more time over AirPlay, yielding the old value for a short while.
        AVMediaSelectionGroup *subtitleGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        if (subtitleGroup) {
            AVMediaSelectionOption *subtitleOption = SRGMediaPlayerControllerAutomaticSubtitleDefaultOption(subtitleGroup.srgmediaplayer_languageOptions, option);
            [playerItem selectMediaOption:subtitleOption inMediaSelectionGroup:subtitleGroup];
        }
    }
    
    [self updateTracksForPlayer:self.player];
}

- (void)selectMediaOptionAutomaticallyInMediaSelectionGroupWithCharacteristic:(AVMediaCharacteristic)characteristic
{
    AVPlayerItem *playerItem = self.player.currentItem;
    AVAsset *asset = playerItem.asset;
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] != AVKeyValueStatusLoaded) {
        return;
    }
    
    AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:characteristic];
    if (! group) {
        return;
    }
    
    if ([characteristic isEqualToString:AVMediaCharacteristicAudible]) {
        AVMediaSelectionOption *audioOption = SRGMediaPlayerControllerAutomaticAudioDefaultOption(group.options);
        [playerItem selectMediaOption:audioOption inMediaSelectionGroup:group];
    }
    else if ([characteristic isEqualToString:AVMediaCharacteristicLegible]) {
        AVMediaSelectionGroup *audioGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        AVMediaSelectionOption *audioOption = audioGroup ? [playerItem srgmediaplayer_selectedMediaOptionInMediaSelectionGroup:audioGroup] : nil;
        AVMediaSelectionOption *subtitleOption = SRGMediaPlayerControllerAutomaticSubtitleDefaultOption(group.srgmediaplayer_languageOptions, audioOption);
        [playerItem selectMediaOption:subtitleOption inMediaSelectionGroup:group];
    }
    else {
        [playerItem selectMediaOptionAutomaticallyInMediaSelectionGroup:group];
    }
    
    [self updateTracksForPlayer:self.player];
}

- (AVMediaSelectionOption *)selectedMediaOptionInMediaSelectionGroupWithCharacteristic:(AVMediaCharacteristic)characteristic
{
    AVPlayerItem *playerItem = self.player.currentItem;
    AVAsset *asset = playerItem.asset;
    
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] != AVKeyValueStatusLoaded) {
        return nil;
    }
    
    AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:characteristic];
    return group ? [playerItem srgmediaplayer_selectedMediaOptionInMediaSelectionGroup:group] : nil;
}

- (BOOL)matchesAutomaticSubtitleSelection
{
    AVPlayerItem *playerItem = self.player.currentItem;
    AVAsset *asset = playerItem.asset;
    
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] != AVKeyValueStatusLoaded) {
        return NO;
    }
    
    AVMediaSelectionOption *audioOption = [self selectedMediaOptionInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible];
    AVMediaSelectionGroup *subtitleGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    if (! subtitleGroup) {
        return NO;
    }
    
    AVMediaSelectionOption *subtitleOption = [playerItem srgmediaplayer_selectedMediaOptionInMediaSelectionGroup:subtitleGroup];
    AVMediaSelectionOption *defaultSubtitleOption = SRGMediaPlayerControllerAutomaticSubtitleDefaultOption(subtitleGroup.srgmediaplayer_languageOptions, audioOption);
    if (defaultSubtitleOption) {
        return [defaultSubtitleOption isEqual:subtitleOption];
    }
    else {
        return ! subtitleOption || [subtitleOption hasMediaCharacteristic:AVMediaCharacteristicContainsOnlyForcedSubtitles];
    }
}

#pragma mark Time observers

- (void)registerTimeObserversForPlayer:(AVPlayer *)player
{
    for (SRGPeriodicTimeObserver *playbackBlockRegistration in [self.periodicTimeObservers allValues]) {
        [playbackBlockRegistration attachToMediaPlayer:player];
    }
    
    @weakify(self)
    self.playerPeriodicTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        
        [self updateSegmentStatusForPlaybackState:self.playbackState previousPlaybackState:self.playbackState time:time];
        
        // Akamai fix: When start and end parameters are used, the subtitles track is longer than the associated truncated
        // stream. This incorrectly prevents the player from ending playback correctly (playback continues for the subtitles).
        // This workaround emits the missing end event instead of letting playback continue.
        // TODO: Remove when Akamai fixed this issue
        if (self.streamType == SRGMediaPlayerStreamTypeOnDemand && CMTIME_COMPARE_INLINE(time, >, CMTimeRangeGetEnd(self.timeRange))) {
            [self setPlaybackState:SRGMediaPlayerPlaybackStateEnded withUserInfo:nil];
        }
    }];
    
    self.controllerPeriodicTimeObserver = [self addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        [self updatePlaybackInformationForPlayer:player];
        [self updateTracksForPlayer:player];
    }];
}

- (void)unregisterTimeObserversForPlayer:(AVPlayer *)player
{
    [player removeTimeObserver:self.playerPeriodicTimeObserver];
    self.playerPeriodicTimeObserver = nil;
    
    [self removePeriodicTimeObserver:self.controllerPeriodicTimeObserver];
    
    for (SRGPeriodicTimeObserver *periodicTimeObserver in [self.periodicTimeObservers allValues]) {
        [periodicTimeObserver detachFromMediaPlayer];
    }
}

- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block
{
    if (! block) {
        return nil;
    }
    
    NSString *identifier = NSUUID.UUID.UUIDString;
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
    if (! observer) {
        return;
    }
    
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

#pragma mark SRGMediaPlayerViewDelegate protocol

- (void)mediaPlayerView:(SRGMediaPlayerView *)mediaPlayerView didMoveToWindow:(UIWindow *)window
{
    [self reloadPlayerConfiguration];
}

#pragma mark SRGPlayerDelegate protocol

- (void)player:(SRGPlayer *)player willSeekToTime:(CMTime)time
{
    [self setPlaybackState:SRGMediaPlayerPlaybackStateSeeking withUserInfo:nil];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[SRGMediaPlayerSeekTimeKey] = [NSValue valueWithCMTime:time];
    userInfo[SRGMediaPlayerSeekDateKey] = [self streamDateForTime:time];
    
    CMTime lastPlaybackTime = player.currentTime;
    userInfo[SRGMediaPlayerLastPlaybackTimeKey] = [NSValue valueWithCMTime:lastPlaybackTime];
    userInfo[SRGMediaPlayerLastPlaybackDateKey] = [self streamDateForTime:lastPlaybackTime];
    
    [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerSeekNotification
                                                      object:self
                                                    userInfo:userInfo.copy];
}

- (void)player:(SRGPlayer *)player didSeekToTime:(CMTime)time
{
    [self setPlaybackState:(player.rate == 0.f) ? SRGMediaPlayerPlaybackStatePaused : SRGMediaPlayerPlaybackStatePlaying withUserInfo:nil];
}

#pragma mark Notifications

- (void)srg_mediaPlayerController_playerItemDidPlayToEndTime:(NSNotification *)notification
{
    [self setPlaybackState:SRGMediaPlayerPlaybackStateEnded withUserInfo:nil];
}

- (void)srg_mediaPlayerController_playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
    [self stopWithUserInfo:nil];
    
    NSError *error = SRGMediaPlayerControllerError(notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey]);
    [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerPlaybackDidFailNotification
                                                      object:self
                                                    userInfo:@{ SRGMediaPlayerErrorKey: error }];
    
    SRGMediaPlayerLogDebug(@"Controller", @"Playback did fail with error: %@", error);
}

- (void)srg_mediaPlayerController_applicationDidEnterBackground:(NSNotification *)notification
{
    if (! self.playerViewController && ! [self isPictureInPictureActive] && ! self.player.externalPlaybackActive) {
        if (self.view.window && self.mediaType == SRGMediaPlayerMediaTypeVideo) {
            switch (self.viewBackgroundBehavior) {
                case SRGMediaPlayerViewBackgroundBehaviorAttached: {
                    [self.player pause];
                    break;
                }
                    
#if TARGET_OS_IOS
                case SRGMediaPlayerViewBackgroundBehaviorDetachedWhenDeviceLocked: {
                    // To determine whether a background entry is due to the lock screen being enabled or not, we need to wait a little bit.
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (UIDevice.srg_mediaPlayer_isLocked) {
                            [self attachPlayer:nil toView:self.view];
                        }
                        else {
                            [self.player pause];
                        }
                    });
                    break;
                }
#endif
                    
                case SRGMediaPlayerViewBackgroundBehaviorDetached: {
                    // The video layer must be detached in the background if we want playback not to be paused automatically.
                    // See https://developer.apple.com/library/archive/qa/qa1668/_index.html
                    [self attachPlayer:nil toView:self.view];
                    break;
                }
            }
        }
        else {
            [self attachPlayer:nil toView:self.view];
        }
    }
    
    [self reloadPlayerConfiguration];
}

- (void)srg_mediaPlayerController_applicationWillEnterForeground:(NSNotification *)notification
{
    [self attachPlayer:self.player toView:self.view];
    [self reloadPlayerConfiguration];
}

#pragma mark KVO

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@keypath(SRGMediaPlayerController.new, playbackState)]
            || [key isEqualToString:@keypath(SRGMediaPlayerController.new, mediaType)]
            || [key isEqualToString:@keypath(SRGMediaPlayerController.new, timeRange)]
            || [key isEqualToString:@keypath(SRGMediaPlayerController.new, streamType)]
            || [key isEqualToString:@keypath(SRGMediaPlayerController.new, live)]) {
        return NO;
    }
    else {
        return [super automaticallyNotifiesObserversForKey:key];
    }
}

#pragma mark Description

- (NSString *)description
{
    CMTimeRange timeRange = self.timeRange;
    return [NSString stringWithFormat:@"<%@: %p; playbackState = %@; mediaType = %@; streamType = %@; live = %@; "
            "URLAsset = %@; segments = %@; userInfo = %@; minimumDVRWindowLength = %@; liveTolerance = %@; "
            "timeRange = (%@, %@); currentTime = %@>",
            self.class,
            self,
            SRGMediaPlayerControllerNameForPlaybackState(self.playbackState),
            SRGMediaPlayerControllerNameForMediaType(self.mediaType),
            SRGMediaPlayerControllerNameForStreamType(self.streamType),
            self.live ? @"YES" : @"NO",
            self.URLAsset,
            self.segments,
            self.userInfo,
            @(self.minimumDVRWindowLength),
            @(self.liveTolerance),
            @(CMTimeGetSeconds(timeRange.start)),
            @(CMTimeGetSeconds(CMTimeRangeGetEnd(timeRange))),
            @(CMTimeGetSeconds(self.currentTime))];
}

@end

#pragma mark Functions

static NSError *SRGMediaPlayerControllerError(NSError *underlyingError)
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = SRGMediaPlayerLocalizedString(@"The media cannot be played", @"Error message when the media cannot be played due to a technical error.");
    userInfo[NSUnderlyingErrorKey] = underlyingError;
    return [NSError errorWithDomain:SRGMediaPlayerErrorDomain code:SRGMediaPlayerErrorPlayback userInfo:userInfo.copy];
}

static NSString *SRGMediaPlayerControllerNameForPlaybackState(SRGMediaPlayerPlaybackState playbackState)
{
    static NSDictionary<NSNumber *, NSString *> *s_names;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_names = @{ @(SRGMediaPlayerPlaybackStateIdle) : @"idle",
                     @(SRGMediaPlayerPlaybackStatePreparing) : @"preparing",
                     @(SRGMediaPlayerPlaybackStatePlaying) : @"playing",
                     @(SRGMediaPlayerPlaybackStateSeeking) : @"seeking",
                     @(SRGMediaPlayerPlaybackStatePaused) : @"paused",
                     @(SRGMediaPlayerPlaybackStateStalled) : @"stalled",
                     @(SRGMediaPlayerPlaybackStateEnded) : @"ended" };
    });
    return s_names[@(playbackState)] ?: @"unknown";
}

static NSString *SRGMediaPlayerControllerNameForMediaType(SRGMediaPlayerMediaType mediaType)
{
    static NSDictionary<NSNumber *, NSString *> *s_names;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_names = @{ @(SRGMediaPlayerMediaTypeVideo) : @"video",
                     @(SRGMediaPlayerMediaTypeAudio) : @"audio" };
    });
    return s_names[@(mediaType)] ?: @"unknown";
}

static NSString *SRGMediaPlayerControllerNameForStreamType(SRGMediaPlayerStreamType streamType)
{
    static NSDictionary<NSNumber *, NSString *> *s_names;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_names = @{ @(SRGMediaPlayerStreamTypeOnDemand) : @"on-demand",
                     @(SRGMediaPlayerStreamTypeLive) : @"live",
                     @(SRGMediaPlayerStreamTypeDVR) : @"DVR" };
    });
    return s_names[@(streamType)] ?: @"unknown";
}

// Adjust position tolerance settings so that the position is guaranteed to fall within the specified time range. Offsets
// can be provided to trim off a bit of the time range at its start and end. If the time itself lies outside the specified
// range, it is fixed to the nearest end.
static SRGTimePosition *SRGMediaPlayerControllerPositionInTimeRange(SRGTimePosition *timePosition, CMTimeRange timeRange, CMTime startOffset, CMTime endOffset)
{
    NSCAssert(CMTIME_COMPARE_INLINE(startOffset, >=, kCMTimeZero) && CMTIME_COMPARE_INLINE(startOffset, >=, kCMTimeZero), @"Offsets must be positive");
    
    CMTime totalOffset = CMTimeAdd(startOffset, endOffset);
    if (CMTIME_COMPARE_INLINE(totalOffset, <=, timeRange.duration)) {
        timeRange = CMTimeRangeMake(CMTimeAdd(timeRange.start, startOffset), CMTimeSubtract(timeRange.duration, totalOffset));
    }
    
    if (SRG_CMTIMERANGE_IS_NOT_EMPTY(timeRange)) {
        CMTime time = CMTimeMaximum(CMTimeMinimum(timePosition.time, CMTimeRangeGetEnd(timeRange)), timeRange.start);
        CMTime toleranceBefore = CMTimeMaximum(CMTimeMinimum(timePosition.toleranceBefore, CMTimeSubtract(timePosition.time, timeRange.start)), kCMTimeZero);
        CMTime toleranceAfter = CMTimeMaximum(CMTimeMinimum(timePosition.toleranceAfter, CMTimeSubtract(CMTimeRangeGetEnd(timeRange), timePosition.time)), kCMTimeZero);
        
        return [SRGTimePosition positionWithTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
    }
    else {
        return timePosition;
    }
}

// Return the default audio option which should be automatically selected in the provided list.
static AVMediaSelectionOption *SRGMediaPlayerControllerAutomaticAudioDefaultOption(NSArray<AVMediaSelectionOption *> *audioOptions)
{
    NSCParameterAssert(audioOptions);
    
    NSMutableOrderedSet<NSString *> *preferredLanguages = [NSMutableOrderedSet orderedSet];
    
    // `AVPlayerViewController` selects the default audio option based on system preferred languages only. This is
    // sub-optimal for apps whose supported languages do not match (e.g. a French-only app, sometimes with subtitles
    // in other languages). To improve this behavior, we prepend the application language to this list, so that the
    // default audio track closely matches the application language.
    [preferredLanguages addObject:SRGMediaPlayerApplicationLocalization()];
    
    NSArray<NSString *> *preferredLocaleIdentifiers = NSLocale.preferredLanguages;
    for (NSString *localeIdentifier in preferredLocaleIdentifiers) {
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:localeIdentifier];
        [preferredLanguages addObject:[locale objectForKey:NSLocaleLanguageCode]];
    }
    
    NSArray<AVMediaSelectionOption *> *options = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:audioOptions filteredAndSortedAccordingToPreferredLanguages:preferredLanguages.array];
    
    // No option matches application or user preferences. It is likely the user cannot understand any of the available
    // languages. Just return the first available language.
    if (options.count == 0) {
        return audioOptions.firstObject;
    }
    
    // A language likely understood by the user has been found. If the corresponding accessibility setting is enabled,
    // try to find an audio described track.
    //
    // Remark: The first audio description track is used, even if a non-described track in another language is located
    //         before in the list. We can namely expect that the user can understand all selected languages, and that
    //         what is more important is that the content is audio described.
    NSArray<AVMediaCharacteristic> *characteristics = CFBridgingRelease(MAAudibleMediaCopyPreferredCharacteristics());
    return [AVMediaSelectionGroup mediaSelectionOptionsFromArray:options withMediaCharacteristics:characteristics].firstObject ?: options.firstObject;
}

// For Automatic mode, return the default subtitle option which should be selected in the provided list (an audio option can be provided to help find the best match).
static AVMediaSelectionOption *SRGMediaPlayerControllerAutomaticSubtitleDefaultOption(NSArray<AVMediaSelectionOption *> *subtitleOptions, AVMediaSelectionOption *audioOption)
{
    NSCParameterAssert(subtitleOptions);
    
    NSString *audioLanguage = [audioOption.locale objectForKey:NSLocaleLanguageCode];
    NSString *applicationLanguage = SRGMediaPlayerApplicationLocalization();
    NSArray<AVMediaCharacteristic> *characteristics = CFBridgingRelease(MACaptionAppearanceCopyPreferredCaptioningMediaCharacteristics(kMACaptionAppearanceDomainUser));
    
    if (characteristics.count != 0
            || (audioLanguage && ! [audioLanguage isEqualToString:applicationLanguage])) {
        return SRGMediaPlayerControllerSubtitleDefaultLanguageOption(subtitleOptions, applicationLanguage, characteristics);
    }
    else {
        return nil;
    }
}

// Return the default subtitle option which should be selected in the provided list, based on on `MediaAccessibility` settings (an audio option can be provided to help
// find the best match).
static AVMediaSelectionOption *SRGMediaPlayerControllerSubtitleDefaultOption(NSArray<AVMediaSelectionOption *> *subtitleOptions, AVMediaSelectionOption *audioOption)
{
    NSCParameterAssert(subtitleOptions);
    
    MACaptionAppearanceDisplayType displayType = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
    switch (displayType) {
        case kMACaptionAppearanceDisplayTypeAutomatic: {
            return SRGMediaPlayerControllerAutomaticSubtitleDefaultOption(subtitleOptions, audioOption);
            break;
        }
            
        case kMACaptionAppearanceDisplayTypeAlwaysOn: {
            NSString *lastSelectedLanguage = SRGMediaAccessibilityCaptionAppearanceLastSelectedLanguage(kMACaptionAppearanceDomainUser);
            NSArray<AVMediaCharacteristic> *characteristics = CFBridgingRelease(MACaptionAppearanceCopyPreferredCaptioningMediaCharacteristics(kMACaptionAppearanceDomainUser));
            return SRGMediaPlayerControllerSubtitleDefaultLanguageOption(subtitleOptions, lastSelectedLanguage, characteristics);
            break;
        }
            
        default: {
            return nil;
            break;
        }
    }
}

// Return the default subtitle option which should be selected in the provided list, matching a specific language and characteristics.
static AVMediaSelectionOption *SRGMediaPlayerControllerSubtitleDefaultLanguageOption(NSArray<AVMediaSelectionOption *> *subtitleOptions, NSString *language, NSArray<AVMediaCharacteristic> *characteristics)
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:language];
    }];
    NSArray<AVMediaSelectionOption *> *options = [[AVMediaSelectionGroup mediaSelectionOptionsFromArray:subtitleOptions withoutMediaCharacteristics:@[AVMediaCharacteristicContainsOnlyForcedSubtitles]] filteredArrayUsingPredicate:predicate];
    
    // Attempt to find a better match depending on the provided characteristics
    if (characteristics.count != 0) {
        return [AVMediaSelectionGroup mediaSelectionOptionsFromArray:options withMediaCharacteristics:characteristics].firstObject ?: options.firstObject;
    }
    // No characteristics provided. At least attempt to avoid closed captions
    else {
        return [AVMediaSelectionGroup mediaSelectionOptionsFromArray:options withoutMediaCharacteristics:@[AVMediaCharacteristicTranscribesSpokenDialogForAccessibility]].firstObject ?: options.firstObject;
    }
}
