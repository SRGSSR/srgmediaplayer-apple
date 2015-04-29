//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineView.h"

static const CGFloat RTSTimelineBarHeight = 2.f;
static const CGFloat RTSTimelineBarMargin = 8.f;
static const CGFloat RTSTimelineEventViewSide = 8.f;

static void commonInit(RTSTimelineView *self)
{
	UIView *barView = [[UIView alloc] initWithFrame:CGRectMake(RTSTimelineBarMargin,
															   roundf((CGRectGetHeight(self.frame) - RTSTimelineBarHeight) / 2.f),
															   CGRectGetWidth(self.frame) - 2.f * RTSTimelineBarMargin,
															   RTSTimelineBarHeight)];
	barView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
	barView.backgroundColor = [UIColor whiteColor];
	[self addSubview:barView];
}

@interface RTSTimelineView ()

@property (nonatomic) NSArray *eventViews;

@end

@implementation RTSTimelineView

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
	
	NSInteger numberOfEvents = [self.dataSource numberOfEventsInTimelineView:self];
	
	NSMutableArray *eventViews = [NSMutableArray array];
	for (NSInteger i = 0; i < numberOfEvents; ++i)
	{
//		RTSTimelineEvent *event = [self.dataSource timelineView:self eventAtIndex:i];
		UIView *eventView = [[UIView alloc] initWithFrame:CGRectMake(RTSTimelineBarMargin + 30.f * i,
																	 roundf((CGRectGetHeight(self.frame) - RTSTimelineEventViewSide) / 2.f),
																	 RTSTimelineEventViewSide,
																	 RTSTimelineEventViewSide)];
		eventView.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.6f];
		eventView.layer.cornerRadius = RTSTimelineEventViewSide / 2.f;
		eventView.layer.borderColor = [UIColor blackColor].CGColor;
		eventView.layer.borderWidth = 1.f;
		eventView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin| UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[self addSubview:eventView];
		
		[eventViews addObject:eventView];
	}
	self.eventViews = [NSArray arrayWithArray:eventViews];
}

@end
