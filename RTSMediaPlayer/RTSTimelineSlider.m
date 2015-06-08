//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "RTSTimelineSlider.h"

#import "RTSMediaPlayerController.h"
#import "RTSMediaSegment.h"
#import "RTSMediaSegmentsController.h"
#import "NSBundle+RTSMediaPlayer.h"

@implementation RTSTimelineSlider

#pragma mark - Object lifecycle

- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self setup_RTSTimelineSlider];
	}
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setup_RTSTimelineSlider];
	}
	return self;
}

- (void)setup_RTSTimelineSlider
{
	NSString *thumbImagePath = [[NSBundle RTSMediaPlayerBundle] pathForResource:@"thumb_timeline_slider" ofType:@"png"];
	UIImage *thumbImage = [UIImage imageWithContentsOfFile:thumbImagePath];
	[self setThumbImage:thumbImage forState:UIControlStateNormal];
	[self setThumbImage:thumbImage forState:UIControlStateHighlighted];
	
	// Add the ability to tap anywhere to seek at this specific location
	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(seekOnTap:)];
	[self addGestureRecognizer:gestureRecognizer];
}

#pragma mark - Overrides

- (void)layoutSubviews
{
	[super layoutSubviews];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	CMTimeRange currentTimeRange = [self currentTimeRange];
	if (CMTIMERANGE_IS_EMPTY(currentTimeRange))
	{
		return;
	}
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGRect trackRect = [self trackRectForBounds:rect];
	CGFloat thumbStartXPos = CGRectGetMidX([self thumbRectForBounds:rect trackRect:trackRect value:self.minimumValue]);
	CGFloat thumbEndXPos = CGRectGetMidX([self thumbRectForBounds:rect trackRect:trackRect value:self.maximumValue]);
	
	for (id<RTSMediaSegment> segment in self.segmentsController.visibleSegments)
	{	
		// Skip events not in the timeline
		if (CMTIME_COMPARE_INLINE(segment.timeRange.start, < , currentTimeRange.start)
			|| CMTIME_COMPARE_INLINE(segment.timeRange.start, >, CMTimeRangeGetEnd(currentTimeRange)))
		{
			continue;
		}
		
		CGFloat tickXPos = thumbStartXPos + (CMTimeGetSeconds(segment.timeRange.start) / CMTimeGetSeconds(currentTimeRange.duration)) * (thumbEndXPos - thumbStartXPos);
		
		UIImage *iconImage = nil;
		if ([self.delegate respondsToSelector:@selector(timelineSlider:iconImageForSegment:)]) {
			iconImage = [self.delegate timelineSlider:self iconImageForSegment:segment];
		}
		
		if (iconImage)
		{
			CGFloat iconSide = 15.f;
			
			CGRect tickRect = CGRectMake(tickXPos - iconSide / 2.f,
										 CGRectGetMidY(trackRect) - iconSide / 2.f,
										 iconSide,
										 iconSide);
			[iconImage drawInRect:tickRect];
		}
		else
		{
			static const CGFloat kTickWidth = 3.f;
			CGFloat tickHeight = 19.f;
			
			CGContextSetLineWidth(context, 1.f);
			CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
			CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
			
			CGRect tickRect = CGRectMake(tickXPos - kTickWidth / 2.f,
										 CGRectGetMidY(trackRect) - tickHeight / 2.f,
										 kTickWidth,
										 tickHeight);
			UIBezierPath *path = [UIBezierPath bezierPathWithRect:tickRect];
			[path fill];
			[path stroke];
		}
	}
}

#pragma mark - Display

- (CMTimeRange) currentTimeRange
{
	AVPlayerItem *playerItem = self.playbackController.playerItem;
	
	NSValue *firstSeekableTimeRangeValue = [playerItem.seekableTimeRanges firstObject];
	if (!firstSeekableTimeRangeValue) {
		return kCMTimeRangeZero;
	}
	
	NSValue *lastSeekableTimeRangeValue = [playerItem.seekableTimeRanges lastObject];
	if (!lastSeekableTimeRangeValue) {
		return kCMTimeRangeZero;
	}
	
	CMTimeRange firstSeekableTimeRange = [firstSeekableTimeRangeValue CMTimeRangeValue];
	CMTimeRange lastSeekableTimeRange = [firstSeekableTimeRangeValue CMTimeRangeValue];
	
	if (!CMTIMERANGE_IS_VALID(firstSeekableTimeRange) || !CMTIMERANGE_IS_VALID(lastSeekableTimeRange)) {
		return kCMTimeRangeZero;
	}
	
	return CMTimeRangeFromTimeToTime(firstSeekableTimeRange.start, CMTimeRangeGetEnd(lastSeekableTimeRange));
}

#pragma mark - Data

- (void) reloadSegmentsForIdentifier:(NSString *)identifier
{
	[self.segmentsController reloadSegmentsForIdentifier:identifier completionHandler:^(NSError *error){
		[self setNeedsDisplay];
	}];
}

#pragma mark - Gestures

- (void)seekOnTap:(UIGestureRecognizer *)gestureRecognizer
{
	// Cannot tap on the thumb itself
	if (self.highlighted) {
		return;
	}
	
	CGFloat xPos = [gestureRecognizer locationInView:self].x;
	float value = self.minimumValue + (self.maximumValue - self.minimumValue) * xPos / CGRectGetWidth(self.bounds);
	
	CMTime time = CMTimeMakeWithSeconds(value, 1.);
	[self.playbackController seekToTime:time completionHandler:nil];
}

@end

