//
//  Created by Samuel Défago on 06.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineOverview.h"

#import "RTSTimelineView+Private.h"

static const CGFloat RTSTimelineEventIconSide = 16.f;
static const CGFloat RTSTimelineBarHorizontalMargin = 2.f * RTSTimelineEventIconSide;

static void *s_kvoContext = &s_kvoContext;

@interface RTSTimelineOverview ()

@property (nonatomic) NSArray *eventViews;

@end

@implementation RTSTimelineOverview

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

- (void) drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1.f);
	CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
	
	CGFloat lengths[] = {2, 3};
	CGContextSetLineDash(context, 0, lengths, sizeof(lengths) / sizeof(CGFloat));
	CGContextMoveToPoint(context, RTSTimelineBarHorizontalMargin, CGRectGetMidY(self.bounds));
	CGContextAddLineToPoint(context, CGRectGetWidth(self.bounds) - RTSTimelineBarHorizontalMargin, CGRectGetMidY(self.bounds));
	CGContextStrokePath(context);
}

- (void) reloadData
{
	for (UIView *eventView in self.eventViews)
	{
		[eventView removeFromSuperview];
	}
	
	NSArray *events = self.timelineView.events;
	if (events.count == 0)
	{
		return;
	}
	
	CMTimeRange currentTimeRange = [self currentTimeRange];
	if (CMTIMERANGE_IS_EMPTY(currentTimeRange))
	{
		return;
	}
	
	NSMutableArray *eventViews = [NSMutableArray array];
	for (NSInteger i = 0; i < events.count; ++i)
	{
		RTSTimelineEvent *event = events[i];
		
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
	
	[self highlightVisibleEventIconsAnimated:NO];
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

- (void) highlightVisibleEventIconsAnimated:(BOOL)animated
{
	void (^animations)(void) = ^{
		NSArray *visibleIndexPaths = [self.timelineView indexPathsForVisibleCells];
		
		NSInteger i = 0;
		for (UIView *eventView in self.eventViews)
		{
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
			eventView.transform = [visibleIndexPaths containsObject:indexPath] ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.5f, 0.5f);
			++i;
		}
	};
	
	if (animated)
	{
		[UIView animateWithDuration:0.2 animations:animations];
	}
	else
	{
		animations();
	}
}

#pragma mark - KVO

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == s_kvoContext && [keyPath isEqualToString:@"events"])
	{
		[self reloadData];
	}
	else if (context == s_kvoContext && [keyPath isEqualToString:@"collectionView.contentOffset"])
	{
		[self highlightVisibleEventIconsAnimated:YES];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
