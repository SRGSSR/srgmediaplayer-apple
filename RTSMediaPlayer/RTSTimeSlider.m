//
//  Created by Frédéric Humbert-Droz on 06/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimeSlider.h"
#import <RTSMediaPlayer/RTSMediaPlayerController.h>

#import <libextobjc/EXTScope.h>

#define SLIDER_VERTICAL_CENTER self.frame.size.height/2

@interface UIBezierPath (Image)
/** Returns an image of the path drawn using a stroke */
-(UIImage*) imageWithColor:(UIColor*)color;
@end

@implementation UIBezierPath (Image)

-(UIImage*) imageWithColor:(UIColor*)color {
	// adjust bounds to account for extra space needed for lineWidth
	CGFloat width = self.bounds.size.width + self.lineWidth * 2;
	CGFloat height = self.bounds.size.height + self.lineWidth * 2;
	CGRect bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, width, height);
	
	// create a view to draw the path in
	UIView *view = [[UIView alloc] initWithFrame:bounds];
	
	// begin graphics context for drawing
	UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [[UIScreen mainScreen] scale]);
	
	// configure the view to render in the graphics context
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	
	// get reference to the graphics context
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// translate matrix so that path will be centered in bounds
	CGContextTranslateCTM(context, -(bounds.origin.x - self.lineWidth), -(bounds.origin.y - self.lineWidth));
	
	// set color
	[color set];
	
	// draw the stroke
	[self stroke];
	[self fill];
	
	// get an image of the graphics context
	UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
	
	// end the context
	UIGraphicsEndImageContext();
	
	return viewImage;
}

@end

@interface RTSTimeSlider ()

@property (weak) id periodicTimeObserver;

@end

@implementation RTSTimeSlider

NSString *RTSTimeSliderFormatter(NSTimeInterval seconds)
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



#pragma mark - initialization

- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self setup];
	}
	return self;
}

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		[self setup];
	}
	return self;
}

- (void) setup
{
	UIImage *triangle = [self emptyImage];
	UIImage *image = [triangle resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
	
	[self setMinimumTrackImage:image forState:UIControlStateNormal];
	[self setMaximumTrackImage:image forState:UIControlStateNormal];
	
	[self setThumbImage:[self thumbImage] forState:UIControlStateNormal];
	[self setThumbImage:[self thumbImage] forState:UIControlStateHighlighted];
}

- (void) dealloc
{
	self.mediaPlayerController = nil;
}

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:RTSMediaPlayerPlaybackStateDidChangeNotification object:_mediaPlayerController];
	
	_mediaPlayerController = mediaPlayerController;
	
	if (!mediaPlayerController)
		return;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackStateDidChange:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController];
}

- (BOOL)isDraggable
{
	// A slider knob can be dragged iff it corresponds to a valid range
	return self.minimumValue != self.maximumValue;
}

#pragma mark - Slider Appearance

- (UIImage*) emptyImage
{
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 2)];
	UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0);
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	[[UIColor clearColor] set];
	UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return viewImage;
}

- (UIImage*) thumbImage
{
	UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 15, 15)];
	return [path imageWithColor:[UIColor whiteColor]];
}



#pragma mark - Notifications

- (void) mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	if (mediaPlayerController.playbackState == RTSMediaPlaybackStateIdle)
	{
		[mediaPlayerController.player removeTimeObserver:self.periodicTimeObserver];
	}
	else if (mediaPlayerController.playbackState == RTSMediaPlaybackStateReady)
	{
		@weakify(self)
		self.periodicTimeObserver = [mediaPlayerController.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 5) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
			@strongify(self)
			
			if (!self.isTracking)
			{
				CMTimeRange currentTimeRange = [self currentTimeRange];
				if (!CMTIMERANGE_IS_EMPTY(currentTimeRange))
				{
					self.minimumValue = CMTimeGetSeconds(currentTimeRange.start);
					self.maximumValue = CMTimeGetSeconds(CMTimeRangeGetEnd(currentTimeRange));
					
					AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
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
}



#pragma mark - Time range retrieval and display

- (CMTimeRange) currentTimeRange
{
	// TODO: Should later add support for discontinuous seekable time ranges
	AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
	NSValue *seekableTimeRangeValue = [playerItem.seekableTimeRanges firstObject];
	if (seekableTimeRangeValue)
	{
		CMTimeRange seekableTimeRange = [seekableTimeRangeValue CMTimeRangeValue];
		return CMTIMERANGE_IS_VALID(seekableTimeRange) ? seekableTimeRange : kCMTimeRangeZero;
	}
	else
	{
		return kCMTimeRangeZero;
	}
}

- (void) updateTimeRangeLabels
{
	CMTimeRange currentTimeRange = [self currentTimeRange];
	AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;

	// Live and timeshift feeds in live conditions. This happens when either the following condition
	// is met:
	//  - We have a pure live feed, which is characterized by an empty range
	//  - We have a timeshift feed, which is characterized by an indefinite player item duration, and which is close
	//    to now. We consider a timeshift 'close to now' when the slider is at the end, up to a tolerance small in
	//    comparison to the total time range (without this tolerance, after scrubbing back and forth to the live,
	//    the current slider value might namely be a little bit lagging behind the maximum value). Here we consider
	//    a tolerance corresponding to 1 minute in 8 hours, with a maximum tolerance of 2 minutes
	static const float RTSToleranceFactor = 1.f / (8.f * 60.f);
	static const float RTSMaximumToleranceInSeconds = 2.f * 60.f;
	
	if (CMTIMERANGE_IS_EMPTY(currentTimeRange)
		|| (CMTIME_IS_INDEFINITE(playerItem.duration) && (self.maximumValue - self.value < fminf(RTSToleranceFactor * CMTimeGetSeconds(currentTimeRange.duration), RTSMaximumToleranceInSeconds))))
	{
		self.valueLabel.text = @"--:--";
		self.timeLeftValueLabel.text = @"Live";
	}
	// Video on demand
	else
	{
		self.valueLabel.text = RTSTimeSliderFormatter(self.value);
		self.timeLeftValueLabel.text = RTSTimeSliderFormatter(self.value - self.maximumValue);
	}
}



#pragma mark - Draw Methods

-(void) drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self drawBar:context];
	[self drawDownloadProgressValueBar:context];
	[self drawMinimumValueBar:context];
}

-(void) drawBar:(CGContextRef)context
{
	CGRect trackFrame = [self trackRectForBounds:self.bounds];
	
	CGFloat lineWidth = 3.0f;

	CGContextSetLineWidth(context, lineWidth);
	CGContextSetLineCap(context,kCGLineCapRound);
	CGContextMoveToPoint(context,CGRectGetMinX(trackFrame), SLIDER_VERTICAL_CENTER);
	CGContextAddLineToPoint(context,CGRectGetWidth(trackFrame), SLIDER_VERTICAL_CENTER);
	CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
	CGContextStrokePath(context);
}

-(void) drawDownloadProgressValueBar:(CGContextRef)context
{
	CGRect trackFrame = [self trackRectForBounds:self.bounds];

	CGFloat lineWidth = 1.0f;
	
	CGContextSetLineWidth(context, lineWidth);
	CGContextSetLineCap(context,kCGLineCapButt);
	CGContextMoveToPoint(context,CGRectGetMinX(trackFrame)+2, SLIDER_VERTICAL_CENTER);
	CGContextAddLineToPoint(context,CGRectGetMaxX(trackFrame)-2, SLIDER_VERTICAL_CENTER);
	CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
	CGContextStrokePath(context);
	
	for (NSValue *value in self.mediaPlayerController.player.currentItem.loadedTimeRanges)
	{
		CMTimeRange timeRange = [value CMTimeRangeValue];
		[self drawTimeRangeProgress:timeRange context:context];
	}
}

- (void) drawTimeRangeProgress:(CMTimeRange)timeRange context:(CGContextRef)context
{
	CGFloat lineWidth = 1.0f;
	
	CGFloat duration = CMTimeGetSeconds(self.mediaPlayerController.player.currentItem.duration);
	if (isnan(duration))
		return;
	
	CGRect trackFrame = [self trackRectForBounds:self.bounds];
	
	CGFloat minX = CGRectGetWidth(trackFrame) / duration * CMTimeGetSeconds(timeRange.start);
	CGFloat maxX = CGRectGetWidth(trackFrame) / duration * (CMTimeGetSeconds(timeRange.start)+CMTimeGetSeconds(timeRange.duration));
	
	CGContextSetLineWidth(context, lineWidth);
	CGContextSetLineCap(context,kCGLineCapButt);
	CGContextMoveToPoint(context, minX, SLIDER_VERTICAL_CENTER);
	CGContextAddLineToPoint(context, maxX, SLIDER_VERTICAL_CENTER);
	CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
	CGContextStrokePath(context);
}

-(void) drawMinimumValueBar:(CGContextRef)context
{
	CGRect trackFrame = [self trackRectForBounds:self.bounds];
	CGRect thumbRect = [self thumbRectForBounds:self.bounds trackRect:trackFrame value:self.value];
	
	CGFloat lineWidth = 3.0f;
	
	CGContextSetLineWidth(context, lineWidth);
	CGContextSetLineCap(context,kCGLineCapRound);
	CGContextMoveToPoint(context,CGRectGetMinX(trackFrame), SLIDER_VERTICAL_CENTER);
	CGContextAddLineToPoint(context,CGRectGetMidX(thumbRect), SLIDER_VERTICAL_CENTER);
	CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
	CGContextStrokePath(context);
}



#pragma mark Touch tracking

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	BOOL beginTracking = [super beginTrackingWithTouch:touch withEvent:event];
	if (beginTracking && [self isDraggable])
	{
		[self.mediaPlayerController pause];
	}
	
	return beginTracking;
}

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	BOOL continueTracking = [super continueTrackingWithTouch:touch withEvent:event];
	if (continueTracking && [self isDraggable])
	{
		[self updateTimeRangeLabels];
		[self setNeedsDisplay];
	}
	
	return continueTracking;
}

- (void) endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	if ([self isDraggable] && self.tracking)
	{
		[self.mediaPlayerController.player seekToTime:CMTimeMakeWithSeconds(self.value, 1)];
		[self.mediaPlayerController play];
	}
	
	[super endTrackingWithTouch:touch withEvent:event];
}

@end
