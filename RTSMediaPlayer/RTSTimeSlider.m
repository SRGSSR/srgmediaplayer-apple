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
@property (weak) AVPlayer *player;

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

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.player removeTimeObserver:self.periodicTimeObserver];
	
	self.maximumValueLabel = nil;
	self.valueLabel = nil;
	
	self.player = nil;
	self.periodicTimeObserver = nil;
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackStateDidChange:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackDidFinish:) name:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController];
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
	if (mediaPlayerController.playbackState != RTSMediaPlaybackStateReady)
		return;
	
	[self.player removeTimeObserver:self.periodicTimeObserver];
	self.player = mediaPlayerController.player;

	@weakify(self)
	self.periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 5) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
		@strongify(self)
		if (self.isTracking)
			return;
		
		CMTime endTime = CMTimeConvertScale (self.player.currentItem.asset.duration, self.player.currentTime.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
		if (CMTimeCompare(endTime, kCMTimeZero) != 0)
		{
			Float64 duration = CMTimeGetSeconds(self.player.currentItem.asset.duration);
			self.maximumValue = !isnan(duration) ? duration : 0.0f;
			self.maximumValueLabel.text = RTSTimeSliderFormatter(duration);
			
			Float64 currentTime = CMTimeGetSeconds(self.player.currentTime);
			if (currentTime < 0)
				return;
			
			self.value = currentTime;
			self.valueLabel.text = RTSTimeSliderFormatter(currentTime);
			self.timeLeftValueLabel.text = RTSTimeSliderFormatter(currentTime - duration);
			
			[self setNeedsDisplay];
		}
		else
		{
			self.maximumValue = 0;
			self.value = 0;
		
			self.maximumValueLabel.text = @"--:--";
			self.valueLabel.text = @"--:--";
			self.timeLeftValueLabel.text = @"--:--";
		}
	}];
}

- (void) mediaPlayerPlaybackDidFinish:(NSNotification *)notification
{
	[self.player removeTimeObserver:self.periodicTimeObserver];
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
	
	for (NSValue *value in self.player.currentItem.loadedTimeRanges)
	{
		CMTimeRange timeRange = [value CMTimeRangeValue];
		[self drawTimeRangeProgress:timeRange context:context];
	}
}

- (void) drawTimeRangeProgress:(CMTimeRange)timeRange context:(CGContextRef)context
{
	CGFloat lineWidth = 1.0f;
	
	CGFloat duration = CMTimeGetSeconds(self.player.currentItem.duration);
	if (isnan(duration))
		return;
	
	CGRect trackFrame = [self trackRectForBounds:self.bounds];
	
	CGFloat minX = CGRectGetWidth(trackFrame) / CMTimeGetSeconds(self.player.currentItem.duration) * CMTimeGetSeconds(timeRange.start);
	CGFloat maxX = CGRectGetWidth(trackFrame) / CMTimeGetSeconds(self.player.currentItem.duration) * (CMTimeGetSeconds(timeRange.start)+CMTimeGetSeconds(timeRange.duration));
	
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
	if (beginTracking)
		[self.player pause];
	
	return beginTracking;
}

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	BOOL continueTracking = [super continueTrackingWithTouch:touch withEvent:event];
	if (continueTracking)
		[self setNeedsDisplay];
		
	return continueTracking;
}

- (void) endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (self.tracking)
		[self.mediaPlayerController seekToTime:self.value];
	
	[super endTrackingWithTouch:touch withEvent:event];
}

@end
