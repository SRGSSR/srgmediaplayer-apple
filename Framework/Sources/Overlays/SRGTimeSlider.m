//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGTimeSlider.h"

#import "NSBundle+SRGMediaPlayer.h"
#import "UIBezierPath+SRGMediaPlayer.h"

#import <libextobjc/libextobjc.h>

static void commonInit(SRGTimeSlider *self);

// Cannot sadly use NSDateComponentsFormatter, impossible to get compact strings with different components if hours must
// be displayed or not
static NSString *SRGTimeSliderFormatter(NSTimeInterval seconds)
{
    if (isnan(seconds)) {
        return @"NaN";
    }
    else if (isinf(seconds)) {
        return seconds >= 0 ? @"∞" : @"-∞";
    }
    
    div_t qr = div((int)round(ABS(seconds)), 60);
    int second = qr.rem;
    qr = div(qr.quot, 60);
    int minute = qr.rem;
    int hour = qr.quot;
    
    BOOL negative = seconds < 0;
    if (hour > 0) {
        return [NSString stringWithFormat:@"%@%02d:%02d:%02d", negative ? @"-" : @"", hour, minute, second];
    }
    else {
        return [NSString stringWithFormat:@"%@%02d:%02d", negative ? @"-" : @"", minute, second];
    }
}

@interface SRGTimeSlider ()

@property (weak) id periodicTimeObserver;
@property (nonatomic) UIColor *overriddenThumbTintColor;
@property (nonatomic) UIColor *overriddenMaximumTrackTintColor;
@property (nonatomic) UIColor *overriddenMinimumTrackTintColor;

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

- (BOOL)isDraggable
{
    // A slider knob can be dragged iff it corresponds to a valid range
    return self.minimumValue != self.maximumValue;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor ?: [UIColor blackColor];
}

// Override color properties since the default superclass behavior is to remove corresponding images, which we here
// already set in commonInit() and want to preserve

- (UIColor *)thumbTintColor
{
    return self.overriddenThumbTintColor ?: [UIColor whiteColor];
}

- (void)setThumbTintColor:(UIColor *)thumbTintColor
{
    self.overriddenThumbTintColor = thumbTintColor;
}

- (UIColor *)minimumTrackTintColor
{
    return self.overriddenMinimumTrackTintColor ?: [UIColor whiteColor];
}

- (void)setMinimumTrackTintColor:(UIColor *)minimumTrackTintColor
{
    self.overriddenMinimumTrackTintColor = minimumTrackTintColor;
}

- (UIColor *)maximumTrackTintColor
{
    return self.overriddenMaximumTrackTintColor ?: [UIColor blackColor];
}

- (void)setMaximumTrackTintColor:(UIColor *)maximumTrackTintColor
{
    self.overriddenMaximumTrackTintColor = maximumTrackTintColor;
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)window
{
    [super willMoveToWindow:window];
    
    if (window) {
        @weakify(self)
        self.periodicTimeObserver = [self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMake(1., 5.) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
            
            if (! self.isTracking && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateSeeking) {
                CMTimeRange timeRange = [self.mediaPlayerController timeRange];
                if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeOnDemand && self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
                    self.maximumValue = 0.f;
                    self.value = 0.f;
                    self.userInteractionEnabled = YES;
                }
                else if (! CMTIMERANGE_IS_EMPTY(timeRange) && ! CMTIMERANGE_IS_INDEFINITE(timeRange) && ! CMTIMERANGE_IS_INVALID(timeRange)) {
                    self.maximumValue = CMTimeGetSeconds(timeRange.duration);
                    
                    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
                    self.value = CMTimeGetSeconds(CMTimeSubtract(playerItem.currentTime, timeRange.start));
                    self.userInteractionEnabled = YES;
                }
                else {
                    float value = [self resetValue];
                    self.maximumValue = value;
                    self.value = value;
                    self.userInteractionEnabled = NO;
                }
                                
                [self.delegate timeSlider:self
                   isMovingToPlaybackTime:self.time
                                withValue:self.value
                              interactive:NO];
                
                [self setNeedsDisplay];
                [self updateTimeRangeLabels];
            }
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(timesliderPlaybackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:self.mediaPlayerController];
    }
    else {
        [self.mediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                      object:self.mediaPlayerController];
    }
}

// Take into account the non-standard smaller knob we installed in commonInit()

- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds
{
    CGRect trackFrame = [super trackRectForBounds:self.bounds];
    CGRect thumbRect = [super thumbRectForBounds:self.bounds trackRect:trackFrame value:self.value];
    return CGRectMake(CGRectGetMinX(trackFrame),
                      CGRectGetMinY(trackFrame),
                      CGRectGetMidX(thumbRect) - CGRectGetMinX(trackFrame),
                      CGRectGetHeight(trackFrame));
}

- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds
{
    CGRect trackFrame = [super trackRectForBounds:self.bounds];
    CGRect thumbRect = [super thumbRectForBounds:self.bounds trackRect:trackFrame value:self.value];
    return CGRectMake(CGRectGetMidX(thumbRect),
                      CGRectGetMinY(trackFrame),
                      CGRectGetMaxX(trackFrame) - CGRectGetMidX(thumbRect),
                      CGRectGetHeight(trackFrame));
}

#pragma mark Time display

- (CMTime)time
{
    CMTimeRange timeRange = self.mediaPlayerController.timeRange;
    if (CMTIMERANGE_IS_EMPTY(timeRange)) {
        return kCMTimeZero;
    }
    
    CMTime relativeTime = CMTimeMakeWithSeconds(self.value, NSEC_PER_SEC);
    return CMTimeAdd(timeRange.start, relativeTime);
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

- (void)updateTimeRangeLabels
{
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    if (! playerItem || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded
            || playerItem.status != AVPlayerItemStatusReadyToPlay) {
        self.valueLabel.text = @"--:--";
        self.timeLeftValueLabel.text = @"--:--";
        return;
    }
    
    if (self.live) {
        self.valueLabel.text = @"--:--";
        self.timeLeftValueLabel.text = SRGMediaPlayerLocalizedString(@"Live", nil);
    }
    else {
        self.valueLabel.text = SRGTimeSliderFormatter(self.value);
        self.timeLeftValueLabel.text = SRGTimeSliderFormatter(self.value - self.maximumValue);
    }
}

#pragma mark Touch handling

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL beginTracking = [super beginTrackingWithTouch:touch withEvent:event];
    if (! beginTracking || ! [self isDraggable]) {
        return NO;
    }
    
    return beginTracking;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL continueTracking = [super continueTrackingWithTouch:touch withEvent:event];
    
    if (continueTracking && [self isDraggable]) {
        [self updateTimeRangeLabels];
        [self setNeedsDisplay];
    }
    
    CMTime time = self.time;
    
    if (self.seekingDuringTracking) {
        [self.mediaPlayerController seekEfficientlyToTime:time withCompletionHandler:nil];
    }
    
    // Next, inform that we are sliding to other views.
    [self.delegate timeSlider:self
              isMovingToPlaybackTime:time
                           withValue:self.value
                         interactive:YES];
    
    return continueTracking;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if ([self isDraggable]) {
        [self.mediaPlayerController seekEfficientlyToTime:self.time withCompletionHandler:^(BOOL finished) {
            if (self.resumingAfterSeek) {
                [self.mediaPlayerController play];
            }
        }];
    }
    
    [super endTrackingWithTouch:touch withEvent:event];
}

#pragma mark Images

- (UIImage *)emptyImage
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 2.f, 2.f)];
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0.f);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    [[UIColor clearColor] set];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}

- (UIImage *)thumbImage
{
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.f, 0.f, 15.f, 15.f)];
    return [path srg_imageWithColor:self.thumbTintColor];
}

#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawBar:context];
    [self drawDownloadProgressValueBar:context];
    [self drawMinimumValueBar:context];
}

- (void)drawBar:(CGContextRef)context
{
    CGRect trackFrame = [self trackRectForBounds:self.bounds];
    
    CGFloat lineWidth = 3.f;
    
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextMoveToPoint(context, CGRectGetMinX(trackFrame), CGRectGetMidY(self.bounds));
    CGContextAddLineToPoint(context, CGRectGetWidth(trackFrame), CGRectGetMidY(self.bounds));
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    CGContextStrokePath(context);
}

- (void)drawDownloadProgressValueBar:(CGContextRef)context
{
    CGRect trackFrame = [self trackRectForBounds:self.bounds];
    
    CGFloat lineWidth = 1.f;
    
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetLineCap(context, kCGLineCapButt);
    CGContextMoveToPoint(context, CGRectGetMinX(trackFrame) + 2.f, CGRectGetMidY(self.bounds));
    CGContextAddLineToPoint(context, CGRectGetMaxX(trackFrame) - 2.f, CGRectGetMidY(self.bounds));
    CGContextSetStrokeColorWithColor(context, self.maximumTrackTintColor.CGColor);
    CGContextStrokePath(context);
    
    for (NSValue *value in self.mediaPlayerController.player.currentItem.loadedTimeRanges) {
        CMTimeRange timeRange = [value CMTimeRangeValue];
        [self drawTimeRangeProgress:timeRange context:context];
    }
}

- (void)drawTimeRangeProgress:(CMTimeRange)timeRange context:(CGContextRef)context
{
    CGFloat lineWidth = 1.f;
    
    CGFloat duration = CMTimeGetSeconds(self.mediaPlayerController.player.currentItem.duration);
    if (isnan(duration)) {
        return;
    }
    
    CGRect trackFrame = [self trackRectForBounds:self.bounds];
    
    CGFloat minX = CGRectGetWidth(trackFrame) / duration * CMTimeGetSeconds(timeRange.start);
    CGFloat maxX = CGRectGetWidth(trackFrame) / duration * (CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration));
    
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetLineCap(context, kCGLineCapButt);
    CGContextMoveToPoint(context, minX, CGRectGetMidY(self.bounds));
    CGContextAddLineToPoint(context, maxX, CGRectGetMidY(self.bounds));
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    CGContextStrokePath(context);
}

- (void)drawMinimumValueBar:(CGContextRef)context
{
    CGRect barFrame = [self minimumValueImageRectForBounds:self.bounds];
    
    CGFloat lineWidth = 3.f;
    
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextMoveToPoint(context, CGRectGetMinX(barFrame) - 0.5f, CGRectGetMidY(self.bounds));
    CGContextAddLineToPoint(context, CGRectGetWidth(barFrame), CGRectGetMidY(self.bounds));
    CGContextSetStrokeColorWithColor(context, self.minimumTrackTintColor.CGColor);
    CGContextStrokePath(context);
}

#pragma mark Helpers

- (float)resetValue
{
    return (self.knobLivePosition == SRGTimeSliderLiveKnobPositionLeft) ? 0.f : 1.f;
}

#pragma mark Notifications

- (void)timesliderPlaybackStateDidChange:(NSNotification *)notification
{
    if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        float value = [self resetValue];
        self.value = value;
        self.maximumValue = value;
        
        [self.delegate timeSlider:self isMovingToPlaybackTime:self.time withValue:self.value interactive:NO];
        
        [self setNeedsDisplay];
        [self updateTimeRangeLabels];
    }
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [self setNeedsDisplay];
}

@end

#pragma mark Static functions

static void commonInit(SRGTimeSlider *self)
{
    self.borderColor = nil;                     // Default color
    
    self.minimumValue = 0.f;                    // Always 0
    self.maximumValue = 0.f;
    self.value = 0.f;
    
    UIImage *triangle = [self emptyImage];
    UIImage *image = [triangle resizableImageWithCapInsets:UIEdgeInsetsMake(1.f, 1.f, 1.f, 1.f)];
    
    [self setMinimumTrackImage:image forState:UIControlStateNormal];
    [self setMaximumTrackImage:image forState:UIControlStateNormal];
    
    [self setThumbImage:[self thumbImage] forState:UIControlStateNormal];
    [self setThumbImage:[self thumbImage] forState:UIControlStateHighlighted];
    
    self.seekingDuringTracking = YES;
    self.knobLivePosition = SRGTimeSliderLiveKnobPositionLeft;
}
