//
//  Created by Samuel Défago on 06.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineSlider.h"

#import "RTSTimelineView+Private.h"

static const CGFloat RTSTimelineIconSide = 20.f;
static const CGFloat RTSTimelineSliderTickHeight = 20.f;
static const CGFloat RTSTimelineSliderTickWidth = 4.f;

static void *s_kvoContext = &s_kvoContext;

@implementation RTSTimelineSlider

#pragma mark - Object lifecycle

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
	
	NSArray *events = self.timelineView.events;
	
	for (NSInteger i = 0; i < events.count; ++i)
	{
		RTSTimelineEvent *event = events[i];
		
		// Skip events not in the timeline
		if (CMTIME_COMPARE_INLINE(event.time, < , currentTimeRange.start) || CMTIME_COMPARE_INLINE(event.time, >, CMTimeRangeGetEnd(currentTimeRange)))
		{
			continue;
		}
		
		CGPoint tickPosition = CGPointMake(CGRectGetMinX(trackRect) + CMTimeGetSeconds(event.time) * CGRectGetWidth(trackRect) / CMTimeGetSeconds(currentTimeRange.duration),
										   CGRectGetMidY(trackRect));
		
		if ([self.dataSource respondsToSelector:@selector(timelineSlider:iconImageForEvent:)])
		{
			UIImage *iconImage = [self.dataSource timelineSlider:self iconImageForEvent:event];
			CGRect tickRect = CGRectMake(tickPosition.x - RTSTimelineIconSide / 2.f,
										 tickPosition.y - RTSTimelineIconSide / 2.f,
										 RTSTimelineIconSide,
										 RTSTimelineIconSide);
			[iconImage drawInRect:tickRect];
		}
		else
		{
			CGContextSetLineWidth(context, 1.f);
			CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.f alpha:0.6f].CGColor);
			CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1.f alpha:0.6f].CGColor);
			
			CGRect tickRect = CGRectMake(tickPosition.x - RTSTimelineSliderTickWidth / 2.f,
										 tickPosition.y - RTSTimelineSliderTickHeight / 2.f,
										 RTSTimelineSliderTickWidth,
										 RTSTimelineSliderTickHeight);
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

@end
