//
//  Created by Samuel Défago on 06.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineSlider.h"

#import "NSBundle+RTSMediaPlayer.h"
#import "RTSTimelineView+Private.h"

static void *s_kvoContext = &s_kvoContext;

static void commonInit(RTSTimeSlider *self);

@implementation RTSTimelineSlider

#pragma mark - Object lifecycle

- (instancetype) initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		commonInit(self);
	}
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder])
	{
		commonInit(self);
	}
	return self;
}

- (void) dealloc
{
	// Unregister KVO
	self.timelineView = nil;
}

#pragma mark - Getters and setters

- (void) setTimelineView:(RTSTimelineView *)timelineView
{
	if (_timelineView)
	{
		[_timelineView removeObserver:self forKeyPath:@"events" context:s_kvoContext];
		[_timelineView removeObserver:self forKeyPath:@"collectionView.contentOffset" context:s_kvoContext];
	}
	
	_timelineView = timelineView;
	[timelineView addObserver:self forKeyPath:@"events" options:NSKeyValueObservingOptionNew context:s_kvoContext];
	[timelineView addObserver:self forKeyPath:@"collectionView.contentOffset" options:NSKeyValueObservingOptionNew context:s_kvoContext];
	
	[self setNeedsDisplay];
}

#pragma mark - Overrides

- (void) drawRect:(CGRect)rect
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
	
	NSArray *events = self.timelineView.events;
	
	for (NSInteger i = 0; i < events.count; ++i)
	{
		RTSTimelineEvent *event = events[i];
		
		// Skip events not in the timeline
		if (CMTIME_COMPARE_INLINE(event.time, < , currentTimeRange.start) || CMTIME_COMPARE_INLINE(event.time, >, CMTimeRangeGetEnd(currentTimeRange)))
		{
			continue;
		}
		
		CGFloat tickXPos = thumbStartXPos + (CMTimeGetSeconds(event.time) / CMTimeGetSeconds(currentTimeRange.duration)) * (thumbEndXPos - thumbStartXPos);
		
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
		
		UIImage *iconImage = nil;
		if ([self.dataSource respondsToSelector:@selector(timelineSlider:iconImageForEvent:)])
		{
			iconImage = [self.dataSource timelineSlider:self iconImageForEvent:event];
		}
		
		if (iconImage)
		{
			CGFloat iconSide = [[self.timelineView indexPathsForVisibleCells] containsObject:indexPath] ? 15.f : 9.f;
			
			CGRect tickRect = CGRectMake(tickXPos - iconSide / 2.f,
										 CGRectGetMidY(trackRect) - iconSide / 2.f,
										 iconSide,
										 iconSide);
			[iconImage drawInRect:tickRect];
		}
		else
		{
			static const CGFloat kTickWidth = 3.f;
			CGFloat tickHeight = [[self.timelineView indexPathsForVisibleCells] containsObject:indexPath] ? 19.f : 11.f;
			
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
	AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
	
	NSValue *firstSeekableTimeRangeValue = [playerItem.seekableTimeRanges firstObject];
	if (!firstSeekableTimeRangeValue)
	{
		return kCMTimeRangeZero;
	}
	
	NSValue *lastSeekableTimeRangeValue = [playerItem.seekableTimeRanges lastObject];
	if (!lastSeekableTimeRangeValue)
	{
		return kCMTimeRangeZero;
	}
	
	CMTimeRange firstSeekableTimeRange = [firstSeekableTimeRangeValue CMTimeRangeValue];
	CMTimeRange lastSeekableTimeRange = [firstSeekableTimeRangeValue CMTimeRangeValue];
	
	if (!CMTIMERANGE_IS_VALID(firstSeekableTimeRange) || !CMTIMERANGE_IS_VALID(lastSeekableTimeRange))
	{
		return kCMTimeRangeZero;
	}
	
	return CMTimeRangeFromTimeToTime(firstSeekableTimeRange.start, CMTimeRangeGetEnd(lastSeekableTimeRange));
}

#pragma mark - KVO

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == s_kvoContext && [keyPath isEqualToString:@"events"])
	{
		[self setNeedsDisplay];
	}
	else if (context == s_kvoContext && [keyPath isEqualToString:@"collectionView.contentOffset"])
	{
		[self setNeedsDisplay];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - Gestures

- (void) seek:(UIGestureRecognizer *)gestureRecognizer
{
	// Cannot tap on the thumb itself
	if (self.highlighted)
	{
		return;
	}
	
	CGFloat xPos = [gestureRecognizer locationInView:self].x;
	float value = self.minimumValue + (self.maximumValue - self.minimumValue) * xPos / CGRectGetWidth(self.bounds);
	
	CMTime time = CMTimeMakeWithSeconds(value, 1.);
	[self.mediaPlayerController.player seekToTime:time];
}

@end

#pragma mark - Functions

static void commonInit(RTSTimeSlider *self)
{
	// Use hollow thumb by default (makes events behind it visible)
	// TODO: Provide a customisation mechanism. Use a Bezier path to generate the image instead of a png
	NSString *thumbImagePath = [[NSBundle RTSMediaPlayerBundle] pathForResource:@"thumb_timeline_slider" ofType:@"png"];
	UIImage *thumbImage = [UIImage imageWithContentsOfFile:thumbImagePath];
	[self setThumbImage:thumbImage forState:UIControlStateNormal];
	[self setThumbImage:thumbImage forState:UIControlStateHighlighted];
	
	// Add the ability to tap anywhere to seek at this specific location
	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(seek:)];
	[self addGestureRecognizer:gestureRecognizer];
}
