//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGTimeSlider.h"

#import "CMTimeRange+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "NSDate+SRGMediaPlayer.h"
#import "SRGMediaPlayerController+Private.h"
#import "UIBezierPath+SRGMediaPlayer.h"

@import libextobjc;

static void commonInit(SRGTimeSlider *self);

static NSString *SRGTimeSliderFormatter(NSTimeInterval seconds)
{
    if (seconds < 60. * 60.) {
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute;
            s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        });
        return [s_dateComponentsFormatter stringFromTimeInterval:seconds];
    }
    else {
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour;
            s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        });
        return [s_dateComponentsFormatter stringFromTimeInterval:seconds];
    }
}

// Create a readable time for accessibility purposes
static NSString *SRGTimeSliderAccessibilityFormatter(NSTimeInterval seconds)
{
    if (isnan(seconds) || isinf(seconds)) {
        return nil;
    }
    
    NSCAssert(seconds >= 0, @"A non-negative number of seconds is expected");
    
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    });
    
    return [s_dateComponentsFormatter stringFromTimeInterval:seconds];
}

@interface SRGTimeSlider ()

@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic) NSArray<NSValue *> *previousLoadedTimeRanges;

@end

@implementation SRGTimeSlider

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        commonInit(self);
    }
    return self;
}

- (void)dealloc
{
    self.mediaPlayerController = nil;           // Unregister observers
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [_mediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
        
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                    object:_mediaPlayerController];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerSeekNotification
                                                    object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    
    if (mediaPlayerController) {
        @weakify(self)
        self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
            if (! self.tracking && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateSeeking) {
                [self updateDisplayWithTime:time];
            }
        }];
        [self updateDisplayWithTime:mediaPlayerController.currentTime];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_timeSlider_playbackStateDidChange:)
                                                   name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                 object:mediaPlayerController];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_timeSlider_seek:)
                                                   name:SRGMediaPlayerSeekNotification
                                                 object:mediaPlayerController];
    }
}

- (BOOL)isDraggable
{
    // A slider knob can be dragged iff it corresponds to a valid range
    return self.minimumValue != self.maximumValue;
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self updateDisplayWithTime:self.time];
    }
}

#pragma mark Information display

- (void)updateDisplayWithTime:(CMTime)time
{
    CMTimeRange timeRange = self.mediaPlayerController.timeRange;
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeOnDemand && self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        self.maximumValue = 0.f;
        self.value = 0.f;
        self.userInteractionEnabled = YES;
    }
    else if (SRG_CMTIMERANGE_IS_NOT_EMPTY(timeRange) && SRG_CMTIMERANGE_IS_DEFINITE(timeRange)) {
        self.maximumValue = CMTimeGetSeconds(timeRange.duration);
        self.value = CMTimeGetSeconds(CMTimeSubtract(time, timeRange.start));
        self.userInteractionEnabled = YES;
    }
    else {
        float value = [self resetValue];
        self.maximumValue = value;
        self.value = value;
        self.userInteractionEnabled = NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(timeSlider:isMovingToTime:date:withValue:interactive:)]) {
        NSDate *date = [self.mediaPlayerController streamDateForTime:time];
        [self.delegate timeSlider:self isMovingToTime:time date:date withValue:self.value interactive:NO];
    }

    [self updateTimeRangeLabelsWithTime:time];
}

- (CMTime)time
{
    CMTimeRange timeRange = self.mediaPlayerController.timeRange;
    if (CMTIMERANGE_IS_EMPTY(timeRange)) {
        return kCMTimeZero;
    }
    
    CMTime relativeTime = CMTimeMakeWithSeconds(self.value, NSEC_PER_SEC);
    return CMTimeAdd(timeRange.start, relativeTime);
}

- (NSDate *)date
{
    return [self.mediaPlayerController streamDateForTime:self.time];
}

- (BOOL)isLive
{
    // Live and timeshift feeds in live conditions. This happens when either the following condition
    // is met:
    //  - We have a pure live feed, which is characterized by an empty range
    //  - We have a timeshift feed, which is characterized by an indefinite player item duration, and whose slider knob is
    //    dragged close to now. We consider a timeshift 'close to now' when the slider is at the end, up to a tolerance
    return self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive
        || (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR && (self.maximumValue - self.value < self.mediaPlayerController.liveTolerance));
}

- (BOOL)isReadyToDisplayValues
{
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    return (playerItem && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle
            && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded
            && playerItem.status == AVPlayerItemStatusReadyToPlay
            && self.mediaPlayerController.streamType != SRGMediaPlayerStreamTypeUnknown);
}

- (void)updateTimeRangeLabelsWithTime:(CMTime)time
{
    BOOL isReady = [self isReadyToDisplayValues];
    NSDate *date = [self.mediaPlayerController streamDateForTime:time];
    
    // Value label
    if ([self.delegate respondsToSelector:@selector(timeSlider:labelForValue:time:date:)]) {
        self.valueLabel.attributedText = [self.delegate timeSlider:self labelForValue:self.value time:time date:date];
        
        if ([self.delegate respondsToSelector:@selector(timeSlider:accessibilityLabelForValue:time:date:)]) {
            self.valueLabel.accessibilityLabel = [self.delegate timeSlider:self accessibilityLabelForValue:self.value time:time date:date];
        }
        else {
            self.valueLabel.accessibilityLabel = nil;
        }
    }
    else {
        if (isReady) {
            if (self.live) {
                self.valueLabel.text = SRGMediaPlayerNonLocalizedString(@"--:--");
                self.valueLabel.accessibilityLabel = nil;
            }
            else {
                self.valueLabel.text = SRGTimeSliderFormatter(self.value);
                self.valueLabel.accessibilityLabel = [NSString stringWithFormat:SRGMediaPlayerAccessibilityLocalizedString(@"%@ played", @"Label on slider for time elapsed"), SRGTimeSliderAccessibilityFormatter(self.value)];
            }
        }
        else {
            self.valueLabel.text = SRGMediaPlayerNonLocalizedString(@"--:--");
            self.valueLabel.accessibilityLabel = nil;
        }
    }
    
    // Time left label
    if ([self.delegate respondsToSelector:@selector(timeSlider:timeLeftLabelForValue:time:date:)]) {
        self.timeLeftValueLabel.attributedText = [self.delegate timeSlider:self timeLeftLabelForValue:self.value time:time date:date];
        
        if ([self.delegate respondsToSelector:@selector(timeSlider:timeLeftAccessibilityLabelForValue:time:date:)]) {
            self.timeLeftValueLabel.accessibilityLabel = [self.delegate timeSlider:self timeLeftAccessibilityLabelForValue:self.value time:time date:date];
        }
        else {
            self.timeLeftValueLabel.accessibilityLabel = nil;
        }
    }
    else {
        if (isReady) {
            if (self.live) {
                self.timeLeftValueLabel.text = SRGMediaPlayerLocalizedString(@"Live", @"Very short text on left time label when playing a live stream");
                self.timeLeftValueLabel.accessibilityLabel = nil;
            }
            else {
                NSTimeInterval interval = self.maximumValue - self.value;
                if (SRG_NSTIMEINTERVAL_IS_VALID(interval) && interval >= 0) {
                    self.timeLeftValueLabel.text = SRGTimeSliderFormatter(interval);
                    self.timeLeftValueLabel.accessibilityLabel = [NSString stringWithFormat:SRGMediaPlayerAccessibilityLocalizedString(@"%@ remaining", @"Label on slider for time remaining"), SRGTimeSliderAccessibilityFormatter(interval)];
                }
                else {
                    self.timeLeftValueLabel.text = SRGMediaPlayerNonLocalizedString(@"--:--");
                    self.timeLeftValueLabel.accessibilityLabel = nil;
                }
            }
        }
        else {
            self.timeLeftValueLabel.text = SRGMediaPlayerNonLocalizedString(@"--:--");
            self.timeLeftValueLabel.accessibilityLabel = nil;
        }
    }
}

#pragma mark Touch handling

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL beginTracking = [super beginTrackingWithTouch:touch withEvent:event];
    if (! beginTracking || ! [self isDraggable]) {
        return NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(timeSlider:didStartDraggingAtTime:date:withValue:)]) {
        [self.delegate timeSlider:self didStartDraggingAtTime:self.time date:self.date withValue:self.value];
    }
    
    return beginTracking;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL continueTracking = [super continueTrackingWithTouch:touch withEvent:event];
    
    CMTime time = self.time;
    
    if (continueTracking && [self isDraggable]) {
        [self updateTimeRangeLabelsWithTime:time];
    }
    
    if (self.seekingDuringTracking) {
        [self.mediaPlayerController seekToPosition:[SRGPosition positionAroundTime:time] withCompletionHandler:nil];
    }
    
    if ([self.delegate respondsToSelector:@selector(timeSlider:isMovingToTime:date:withValue:interactive:)]) {
        [self.delegate timeSlider:self isMovingToTime:time date:self.date withValue:self.value interactive:YES];
    }
    
    return continueTracking;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if ([self isDraggable]) {
        [self.mediaPlayerController seekToPosition:[SRGPosition positionAroundTime:self.time] withCompletionHandler:^(BOOL finished) {
            if (self.resumingAfterSeek) {
                [self.mediaPlayerController play];
            }
        }];
    }
    
    if ([self.delegate respondsToSelector:@selector(timeSlider:didStopDraggingAtTime:date:withValue:)]) {
        [self.delegate timeSlider:self didStopDraggingAtTime:self.time date:self.date withValue:self.value];
    }
    
    [super endTrackingWithTouch:touch withEvent:event];
}

#pragma mark Helpers

- (float)resetValue
{
    return (self.knobLivePosition == SRGTimeSliderLiveKnobPositionLeft) ? 0.f : 1.f;
}

#pragma mark Notifications

- (void)srg_timeSlider_playbackStateDidChange:(NSNotification *)notification
{
    if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        self.previousLoadedTimeRanges = nil;
        
        float value = [self resetValue];
        self.value = value;
        self.maximumValue = value;
        
        if ([self.delegate respondsToSelector:@selector(timeSlider:isMovingToTime:date:withValue:interactive:)]) {
            [self.delegate timeSlider:self isMovingToTime:self.time date:self.date withValue:self.value interactive:NO];
        }

        [self updateTimeRangeLabelsWithTime:self.time];
    }
}

- (void)srg_timeSlider_seek:(NSNotification *)notification
{
    // Do not wait for playback to resume to update display, update to the target location of seeks
    CMTime time = [notification.userInfo[SRGMediaPlayerSeekTimeKey] CMTimeValue];
    [self updateDisplayWithTime:time];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    if (! [self isReadyToDisplayValues]) {
        return SRGMediaPlayerAccessibilityLocalizedString(@"No playback", @"Slider label when nothing to play");
    }
    else if (self.live) {
        return SRGMediaPlayerAccessibilityLocalizedString(@"Live playback", @"Slider label when playing live");
    }
    else if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        return [NSString stringWithFormat:SRGMediaPlayerAccessibilityLocalizedString(@"%@ from live", @"Slider label when playing a DVR in the past"),
                SRGTimeSliderAccessibilityFormatter(self.maximumValue - self.value)];
    }
    else {
        return [NSString stringWithFormat:SRGMediaPlayerAccessibilityLocalizedString(@"%@ played", @"Label on slider for time elapsed"), SRGTimeSliderAccessibilityFormatter(self.value)];
    }
}

- (NSString *)accessibilityValue
{
    if (self.live) {
        return nil;
    }
    else {
        return [super accessibilityValue];
    }
}

- (void)accessibilityDecrement
{
    if ([self.delegate respondsToSelector:@selector(timeSlider:accessibilityDecrementFromValue:time:)]) {
        [self.delegate timeSlider:self accessibilityDecrementFromValue:self.value time:self.time];
    }
    else {
        CMTime targetTime = CMTimeSubtract(self.time, CMTimeMakeWithSeconds(15., NSEC_PER_SEC));
        [self.mediaPlayerController seekToPosition:[SRGPosition positionAroundTime:targetTime] withCompletionHandler:nil];
    }
}

- (void)accessibilityIncrement
{
    if ([self.delegate respondsToSelector:@selector(timeSlider:accessibilityIncrementFromValue:time:)]) {
        [self.delegate timeSlider:self accessibilityIncrementFromValue:self.value time:self.time];
    }
    else {
        CMTime targetTime = CMTimeAdd(self.time, CMTimeMakeWithSeconds(15., NSEC_PER_SEC));
        [self.mediaPlayerController seekToPosition:[SRGPosition positionAroundTime:targetTime] withCompletionHandler:nil];
    }
}

@end

#pragma mark Static functions

static void commonInit(SRGTimeSlider *self)
{
    self.minimumValue = 0.f;                    // Always 0
    self.maximumValue = 0.f;
    self.value = 0.f;
    
    self.seekingDuringTracking = YES;
    self.knobLivePosition = SRGTimeSliderLiveKnobPositionLeft;
}

#endif
