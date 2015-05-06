//
//  Created by Samuel Défago on 06.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineOverview.h"

static const CGFloat RTSTimelineEventIconSide = 8.f;
static const CGFloat RTSTimelineBarHorizontalMargin = 2.f * RTSTimelineEventIconSide;

@interface RTSTimelineOverview ()

@property (nonatomic) NSArray *eventViews;

@end

@implementation RTSTimelineOverview

#pragma mark - Getters and setters

- (void) setEvents:(NSArray *)events
{
	_events = events;
	
	[self reloadData];
}

#pragma mark - Overrides

- (void) willMoveToWindow:(UIWindow *)window
{
	[super willMoveToWindow:window];
	
	if (window)
	{
		[self reloadData];
	}
}

- (void) reloadData
{
	for (UIView *eventView in self.eventViews)
	{
		[eventView removeFromSuperview];
	}
	
	if (self.events.count == 0)
	{
		return;
	}
	
	CMTimeRange currentTimeRange = [self currentTimeRange];
	if (CMTIMERANGE_IS_EMPTY(currentTimeRange))
	{
		return;
	}
	
	NSMutableArray *eventViews = [NSMutableArray array];
	for (NSInteger i = 0; i < self.events.count; ++i)
	{
		RTSTimelineEvent *event = self.events[i];
		
		// Skip events not in the timeline
		if (CMTIME_COMPARE_INLINE(event.time, < , currentTimeRange.start) || CMTIME_COMPARE_INLINE(event.time, >, CMTimeRangeGetEnd(currentTimeRange)))
		{
			continue;
		}
		
		CGRect iconFrame = CGRectMake(roundf(RTSTimelineBarHorizontalMargin + CMTimeGetSeconds(event.time) * (CGRectGetWidth(self.frame) - 2.f * RTSTimelineBarHorizontalMargin) / CMTimeGetSeconds(currentTimeRange.duration) - RTSTimelineEventIconSide / 2.f),
									  roundf((CGRectGetHeight(self.frame) - RTSTimelineEventIconSide) / 2.f),
									  RTSTimelineEventIconSide,
									  RTSTimelineEventIconSide);
		
		UIView *eventView = nil;
		if ([self.dataSource respondsToSelector:@selector(timelineOverview:iconImageForEvent:)])
		{
			UIImage *iconImage = [self.dataSource timelineOverview:self iconImageForEvent:event];
			eventView = [[UIImageView alloc] initWithImage:iconImage];
			eventView.contentMode = UIViewContentModeScaleAspectFit;
			eventView.frame = iconFrame;
		}
		else
		{
			eventView = [[UIView alloc] initWithFrame:iconFrame];
			eventView.backgroundColor = [UIColor whiteColor];
			eventView.layer.cornerRadius = RTSTimelineEventIconSide / 2.f;
			eventView.layer.borderColor = [UIColor blackColor].CGColor;
			eventView.layer.borderWidth = 1.f;
		}
		
		eventView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin| UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[self addSubview:eventView];
		
		[eventViews addObject:eventView];
	}
	self.eventViews = [NSArray arrayWithArray:eventViews];
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

@end
