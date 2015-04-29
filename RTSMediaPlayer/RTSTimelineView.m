//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineView.h"

static void commonInit(RTSTimelineView *self)
{
	static const CGFloat RTSTimelineBarHeight = 2.f;
	static const CGFloat RTSTimelineBarMargin = 8.f;
	
	UIView *barView = [[UIView alloc] initWithFrame:CGRectMake(RTSTimelineBarMargin,
															   roundf((CGRectGetHeight(self.frame) - RTSTimelineBarHeight) / 2.f),
															   CGRectGetWidth(self.frame) - 2.f * RTSTimelineBarMargin,
															   RTSTimelineBarHeight)];
	barView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
	barView.backgroundColor = [UIColor whiteColor];
	[self addSubview:barView];
}

@implementation RTSTimelineView

- (instancetype)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		commonInit(self);
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder]) {
		commonInit(self);
	}
	return self;
}

- (void) reloadData
{
	NSInteger numberOfEvents = [self.dataSource numberOfEventsInTimelineView:self];
	for (NSInteger i = 0; i < numberOfEvents; ++i)
	{
		// RTSTimelineEvent *event = [self.dataSource timelineView:self eventAtIndex:i];
		
	}
}

@end
