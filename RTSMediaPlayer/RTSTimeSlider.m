//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "RTSTimeSlider.h"

#import "NSBundle+RTSMediaPlayer.h"
#import "UIBezierPath+RTSMediaPlayerUtils.h"

#import <SRGMediaPlayer/RTSMediaPlayerController.h>
#import <libextobjc/EXTScope.h>

#define SLIDER_VERTICAL_CENTER self.frame.size.height/2

static NSString *RTSTimeSliderFormatter(NSTimeInterval seconds)
{
	if (isnan(seconds))
		return @"NaN";
	else if (isinf(seconds))
		return seconds > 0 ? @"∞" : @"-∞";
	
	div_t qr = div((int)round(ABS(seconds)), 60);
	int second = qr.rem;
	qr = div(qr.quot, 60);
	int minute = qr.rem;
	int hour = qr.quot;
	
	BOOL negative = seconds < 0;
	if (hour > 0)
		return [NSString stringWithFormat:@"%@%02d:%02d:%02d", negative ? @"-" : @"", hour, minute, second];
	else
		return [NSString stringWithFormat:@"%@%02d:%02d", negative ? @"-" : @"", minute, second];
}

@interface RTSTimeSlider ()

@property (weak) id periodicTimeObserver;
@property (nonatomic, strong) UIColor *overriddenThumbTintColor;
@property (nonatomic, strong) UIColor *overriddenMaximumTrackTintColor;
@property (nonatomic, strong) UIColor *overriddenMinimumTrackTintColor;

@end

@implementation RTSTimeSlider

#pragma mark - initialization

- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self setup_RTSTimeSlider];
	}
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		[self setup_RTSTimeSlider];
	}
	return self;
}

- (void) setup_RTSTimeSlider
{
	self.borderColor = [UIColor blackColor];
	
	self.minimumTrackTintColor = [UIColor whiteColor];
	self.maximumTrackTintColor = [UIColor blackColor];
	
	self.thumbTintColor = [UIColor whiteColor];
	
	UIImage *triangle = [self emptyImage];
	UIImage *image = [triangle resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
	
	[self setMinimumTrackImage:image forState:UIControlStateNormal];
	[self setMaximumTrackImage:image forState:UIControlStateNormal];
	
	[self setThumbImage:[self thumbImage] forState:UIControlStateNormal];
	[self setThumbImage:[self thumbImage] forState:UIControlStateHighlighted];
}

#pragma mark - Setters and getters

- (void) setPlaybackController:(id<RTSMediaPlayback>)playbackController
{
	if (_playbackController)
	{
		[_playbackController removePeriodicTimeObserver:self.periodicTimeObserver];
	}
	
	_playbackController = playbackController;
	
	@weakify(self)
	self.periodicTimeObserver = [playbackController addPeriodicTimeObserverForInterval:CMTimeMake(1., 5.) queue:NULL usingBlock:^(CMTime time) {
		@strongify(self)
		
		if (!self.isTracking)
		{
			CMTimeRange currentTimeRange = [self currentTimeRange];
			if (!CMTIMERANGE_IS_EMPTY(currentTimeRange))
			{
				self.minimumValue = CMTimeGetSeconds(currentTimeRange.start);
				self.maximumValue = CMTimeGetSeconds(CMTimeRangeGetEnd(currentTimeRange));
				
				AVPlayerItem *playerItem = self.playbackController.playerItem;
				self.value = CMTimeGetSeconds(playerItem.currentTime);
			}
			else
			{
				self.minimumValue = 0.;
				self.maximumValue = 0.;
				self.value = 0.;
			}
		}
		[self updateTimeRangeLabels];
		[self setNeedsDisplay];
	}];
}

- (BOOL) isDraggable
{
	// A slider knob can be dragged iff it corresponds to a valid range
	return self.minimumValue != self.maximumValue;
}

// Override color properties since the default superclass behavior is to remove corresponding images, which we here
// already set in -setup_RTSTimeSlider and want to preserve

- (UIColor *) thumbTintColor
{
	return self.overriddenThumbTintColor;
}

- (void) setThumbTintColor:(UIColor *)thumbTintColor
{
	self.overriddenThumbTintColor = thumbTintColor;
}

- (UIColor *) minimumTrackTintColor
{
	return self.overriddenMinimumTrackTintColor;
}

- (void) setMinimumTrackTintColor:(UIColor *)minimumTrackTintColor
{
	self.overriddenMinimumTrackTintColor = minimumTrackTintColor;
}

- (UIColor *) maximumTrackTintColor
{
	return self.overriddenMaximumTrackTintColor;
}

- (void) setMaximumTrackTintColor:(UIColor *)maximumTrackTintColor
{
	self.overriddenMaximumTrackTintColor = maximumTrackTintColor;
}


#pragma mark - Time range retrieval and display

- (CMTimeRange)currentTimeRange
{
	// TODO: Should later add support for discontinuous seekable time ranges
	AVPlayerItem *playerItem = self.playbackController.playerItem;
	NSValue *seekableTimeRangeValue = [playerItem.seekableTimeRanges firstObject];
	if (seekableTimeRangeValue) {
		CMTimeRange seekableTimeRange = [seekableTimeRangeValue CMTimeRangeValue];
		return CMTIMERANGE_IS_VALID(seekableTimeRange) ? seekableTimeRange : kCMTimeRangeZero;
	}
	else {
		return kCMTimeRangeZero;
	}
}


// Useful for live streams. How does it work for VOD?
- (CMTime) time
{
    CMTimeRange currentTimeRange = [self currentTimeRange];
    Float64 timeInSeconds = CMTimeGetSeconds(currentTimeRange.start) + (self.value - self.minimumValue) * CMTimeGetSeconds(currentTimeRange.duration) / (self.maximumValue - self.minimumValue);
    return CMTimeMakeWithSeconds(timeInSeconds, 1.);
}

- (CMTime) convertedValueCMTime
{
	CGFloat fraction = (self.value - self.minimumValue) / (self.maximumValue - self.minimumValue);
	CGFloat duration = CMTimeGetSeconds(self.playbackController.playerItem.duration);
	// Assuming start == 0.
	return CMTimeMakeWithSeconds(fraction*duration, NSEC_PER_SEC);
}

- (void) updateTimeRangeLabels
{
	CMTimeRange currentTimeRange = [self currentTimeRange];
	AVPlayerItem *playerItem = self.playbackController.playerItem;
	if (! playerItem || playerItem.status != AVPlayerItemStatusReadyToPlay) {
		self.valueLabel.text = @"--:--";
		self.timeLeftValueLabel.text = @"--:--";
		return;
	}
	
	// Live and timeshift feeds in live conditions. This happens when either the following condition
	// is met:
	//  - We have a pure live feed, which is characterized by an empty range
	//  - We have a timeshift feed, which is characterized by an indefinite player item duration, and which is close
	//    to now. We consider a timeshift 'close to now' when the slider is at the end, up to a tolerance of 15 seconds
	static const float RTSToleranceInSeconds = 15.f;
	
	if (CMTIMERANGE_IS_EMPTY(currentTimeRange)
		|| (CMTIME_IS_INDEFINITE(playerItem.duration) && (self.maximumValue - self.value < RTSToleranceInSeconds)))
	{
		self.valueLabel.text = @"--:--";
		self.timeLeftValueLabel.text = RTSMediaPlayerLocalizedString(@"Live", nil);
	}
	// Video on demand
	else {
		self.valueLabel.text = RTSTimeSliderFormatter(self.value);
		self.timeLeftValueLabel.text = RTSTimeSliderFormatter(self.value - self.maximumValue);		
	}
}


#pragma mark Touch tracking

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	BOOL beginTracking = [super beginTrackingWithTouch:touch withEvent:event];
	if (! beginTracking || ! [self isDraggable]) {
		return NO;
	}
		
	return beginTracking;
}

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	BOOL continueTracking = [super continueTrackingWithTouch:touch withEvent:event];
	
	if (continueTracking && [self isDraggable]) {
		[self updateTimeRangeLabels];
		[self setNeedsDisplay];
	}
	
	CMTime time = [self convertedValueCMTime];
	
	// First seek to the playback controller.
	[self.playbackController seekToTime:time completionHandler:nil];

	// Next, inform that we are sliding to other views.
	if (self.slidingDelegate) {
		[self.slidingDelegate timeSlider:self
				 isSlidingAtPlaybackTime:time
							   withValue:self.value];
	}

	return continueTracking;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	if ([self isDraggable]) {
		// Current time may not be the same as the current value time, if seek is not ended, or is blocked.
		[self.playbackController playAtTime:[self convertedValueCMTime]];
	}
	
	[super endTrackingWithTouch:touch withEvent:event];
}

#pragma mark - Slider Appearance

- (UIImage *)emptyImage
{
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 2)];
	UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0);
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	[[UIColor clearColor] set];
	UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return viewImage;
}

- (UIImage *)thumbImage
{
	UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 15, 15)];
    return [path imageWithColor:self.thumbTintColor];
}



#pragma mark - Draw Methods

- (void) drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self drawBar:context];
	[self drawDownloadProgressValueBar:context];
	[self drawMinimumValueBar:context];
}

- (void) drawBar:(CGContextRef)context
{
	CGRect trackFrame = [self trackRectForBounds:self.bounds];
	
	CGFloat lineWidth = 3.0f;

	CGContextSetLineWidth(context, lineWidth);
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextMoveToPoint(context, CGRectGetMinX(trackFrame), SLIDER_VERTICAL_CENTER);
	CGContextAddLineToPoint(context, CGRectGetWidth(trackFrame), SLIDER_VERTICAL_CENTER);
	CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
	CGContextStrokePath(context);
}

- (void) drawDownloadProgressValueBar:(CGContextRef)context
{
	CGRect trackFrame = [self trackRectForBounds:self.bounds];

	CGFloat lineWidth = 1.0f;
	
	CGContextSetLineWidth(context, lineWidth);
	CGContextSetLineCap(context, kCGLineCapButt);
	CGContextMoveToPoint(context, CGRectGetMinX(trackFrame)+2, SLIDER_VERTICAL_CENTER);
	CGContextAddLineToPoint(context, CGRectGetMaxX(trackFrame)-2, SLIDER_VERTICAL_CENTER);
	CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
	CGContextStrokePath(context);
	
	for (NSValue *value in self.playbackController.playerItem.loadedTimeRanges) {
		CMTimeRange timeRange = [value CMTimeRangeValue];
		[self drawTimeRangeProgress:timeRange context:context];
	}
}

- (void) drawTimeRangeProgress:(CMTimeRange)timeRange context:(CGContextRef)context
{
	CGFloat lineWidth = 1.0f;
	
	CGFloat duration = CMTimeGetSeconds(self.playbackController.playerItem.duration);
	if (isnan(duration))
		return;
	
	CGRect trackFrame = [self trackRectForBounds:self.bounds];
	
	CGFloat minX = CGRectGetWidth(trackFrame) / duration * CMTimeGetSeconds(timeRange.start);
	CGFloat maxX = CGRectGetWidth(trackFrame) / duration * (CMTimeGetSeconds(timeRange.start)+CMTimeGetSeconds(timeRange.duration));
	
	CGContextSetLineWidth(context, lineWidth);
	CGContextSetLineCap(context,kCGLineCapButt);
	CGContextMoveToPoint(context, minX, SLIDER_VERTICAL_CENTER);
	CGContextAddLineToPoint(context, maxX, SLIDER_VERTICAL_CENTER);
	CGContextSetStrokeColorWithColor(context, self.maximumTrackTintColor.CGColor);
	CGContextStrokePath(context);
}

- (void) drawMinimumValueBar:(CGContextRef)context
{
	CGRect barFrame = [self minimumValueImageRectForBounds:self.bounds];
	
	CGFloat lineWidth = 3.0f;

	CGContextSetLineWidth(context, lineWidth);
	CGContextSetLineCap(context,kCGLineCapRound);
	CGContextMoveToPoint(context,CGRectGetMinX(barFrame), SLIDER_VERTICAL_CENTER);
	CGContextAddLineToPoint(context, CGRectGetWidth(barFrame), SLIDER_VERTICAL_CENTER);
	CGContextSetStrokeColorWithColor(context, self.minimumTrackTintColor.CGColor);
	CGContextStrokePath(context);
}

#pragma mark - Overrides

// Take into account the non-standard smaller knob we installed in -setup_RTSTimeSlider

- (CGRect) minimumValueImageRectForBounds:(CGRect)bounds
{
	CGRect trackFrame = [super trackRectForBounds:self.bounds];
	CGRect thumbRect = [super thumbRectForBounds:self.bounds trackRect:trackFrame value:self.value];
	return CGRectMake(CGRectGetMinX(trackFrame),
					  CGRectGetMinY(trackFrame),
					  CGRectGetMidX(thumbRect) - CGRectGetMinX(trackFrame),
					  CGRectGetHeight(trackFrame));
}

- (CGRect) maximumValueImageRectForBounds:(CGRect)bounds
{
	CGRect trackFrame = [super trackRectForBounds:self.bounds];
	CGRect thumbRect = [super thumbRectForBounds:self.bounds trackRect:trackFrame value:self.value];
	return CGRectMake(CGRectGetMidX(thumbRect),
					  CGRectGetMinY(trackFrame),
					  CGRectGetMaxX(trackFrame) - CGRectGetMidX(thumbRect),
					  CGRectGetHeight(trackFrame));
}

@end
