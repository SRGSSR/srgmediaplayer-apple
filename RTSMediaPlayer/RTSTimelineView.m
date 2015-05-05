//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineView.h"

#import "RTSMediaPlayerController.h"

// Constants
static const CGFloat RTSTimelineBarHeight = 2.f;
static const CGFloat RTSTimelineEventIconSide = 8.f;
static const CGFloat RTSTimelineCollectionVerticalMargin = 4.f;
static const CGFloat RTSTimelineBarHorizontalMargin = 2.f * RTSTimelineEventIconSide;

// Function declarations
static void commonInit(RTSTimelineView *self);

@interface RTSTimelineView ()

@property (nonatomic) NSArray *iconViews;

@property (nonatomic, weak) UICollectionView *eventCollectionView;
@property (nonatomic, weak) UIView *overviewView;
@property (nonatomic, weak) UIView *barView;

@end

@implementation RTSTimelineView

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

#pragma mark - Getters and setters

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	_mediaPlayerController = mediaPlayerController;
	
	// Ensure the timeline stays up to date as playable time ranges change
	[mediaPlayerController addPlaybackTimeObserverForInterval:CMTimeMakeWithSeconds(5., 1.) queue:NULL usingBlock:^(CMTime time) {
		[self reloadTimeline];
	}];
}

- (void) setEvents:(NSArray *)events
{
	_events = events;
	
	[self reloadTimeline];
	[self.eventCollectionView reloadData];
}

#pragma mark - Overrides

- (void) willMoveToWindow:(UIWindow *)window
{
	[super willMoveToWindow:window];
	
	if (window)
	{
		[self reloadTimeline];
	}
}

- (void) layoutSubviews
{
	[super layoutSubviews];
	
	UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.eventCollectionView.collectionViewLayout;
	collectionViewLayout.minimumLineSpacing = [self.delegate respondsToSelector:@selector(itemSpacingForTimelineView:)] ? [self.delegate itemSpacingForTimelineView:self] : 0.f;
	
	CGFloat cellSide = CGRectGetHeight(self.eventCollectionView.frame);
	collectionViewLayout.itemSize = CGSizeMake([self.delegate itemWidthForTimelineView:self], cellSide);
	[collectionViewLayout invalidateLayout];
}

#pragma mark - Display

- (void) reloadTimeline
{
	for (UIView *iconView in self.iconViews)
	{
		[iconView removeFromSuperview];
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
	
	NSMutableArray *iconViews = [NSMutableArray array];
	for (NSInteger i = 0; i < self.events.count; ++i)
	{
		RTSTimelineEvent *event = self.events[i];
		
		// Skip events not in the timeline
		if (CMTIME_COMPARE_INLINE(event.time, < , currentTimeRange.start) || CMTIME_COMPARE_INLINE(event.time, >, CMTimeRangeGetEnd(currentTimeRange)))
		{
			continue;
		}
		
		UIView *iconView = [[UIView alloc] initWithFrame:CGRectMake(roundf(RTSTimelineBarHorizontalMargin + CMTimeGetSeconds(event.time) * (CGRectGetWidth(self.overviewView.frame) - 2.f * RTSTimelineBarHorizontalMargin) / CMTimeGetSeconds(currentTimeRange.duration) - RTSTimelineEventIconSide / 2.f),
																	roundf((CGRectGetHeight(self.overviewView.frame) - RTSTimelineEventIconSide) / 2.f),
																	RTSTimelineEventIconSide,
																	RTSTimelineEventIconSide)];
		iconView.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.6f];
		iconView.layer.cornerRadius = RTSTimelineEventIconSide / 2.f;
		iconView.layer.borderColor = [UIColor blackColor].CGColor;
		iconView.layer.borderWidth = 1.f;
		iconView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin| UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[self.overviewView addSubview:iconView];
		
		[iconViews addObject:iconView];
	}
	self.iconViews = [NSArray arrayWithArray:iconViews];
}

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

#pragma mark - Cell reuse

- (void) registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier
{
	[self.eventCollectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

- (void) registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier
{
	[self.eventCollectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (id) dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forEvent:(RTSTimelineEvent *)event
{
	NSInteger index = [self.events indexOfObject:event];
	if (index == NSNotFound)
	{
		return nil;
	}
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	return [self.eventCollectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
}

#pragma mark - UICollectionViewDataSource protocol

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.events count];
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	RTSTimelineEvent *event = self.events[indexPath.row];
	return [self.dataSource timelineView:self cellForEvent:event];
}

#pragma mark - UICollectionViewDelegate protocol

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	RTSTimelineEvent *event = self.events[indexPath.row];
	
	if ([self.delegate respondsToSelector:@selector(timelineView:didSelectEvent:)])
	{
		[self.delegate timelineView:self didSelectEvent:event];
	}
	else
	{
		[self.mediaPlayerController.player seekToTime:event.time];
	}
}

@end

#pragma mark - Functions

/**
 * The timeline layout is created entirely in code and looks as follows:
 *
 *      ┌──────────────────────────────────────────────────────────────────┐
 *      ├──────────────────────────────────────────────────────────────────┤   ■
 *      │┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┌ ─ ─ ┤   │
 *      │                                                                  │   │
 *      ││                           │ │                           │ │     │   │
 *      │                                                                  │   │
 *      ││                           │ │                           │ │     │   │
 *      │                                                                  │   │
 *      ││      eventCollectionView  │ │                           │ │     │   │   4 times
 *      │                                                                  │   │ taller than
 *      ││                           │ │                           │ │     │   │  overview
 *      │                                                                  │   │
 *      ││                           │ │                           │ │     │   │
 *      │                                                                  │   │
 *      ││                           │ │                           │ │     │   │
 *      │                                                                  │   │
 *      ││                           │ │                           │ │     │   │
 *      │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   ─ ─ ─│   │
 *      ├──────────────────────────────────────────────────────────────────┤   ■
 *      │  overviewView                                                    │
 *      │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━barView━━━━━━━━━━━━━━━━━  │
 *      │                                                                  │
 *      └──────────────────────────────────────────────────────────────────┘
 */
static void commonInit(RTSTimelineView *self)
{
	// Collection view layout for easy navigation between events
	UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
	collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	collectionViewLayout.minimumLineSpacing = 0.f;
	
	// Collection view
	UICollectionView *eventCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
	eventCollectionView.backgroundColor = [UIColor clearColor];
	eventCollectionView.alwaysBounceHorizontal = YES;
	eventCollectionView.dataSource = self;
	eventCollectionView.delegate = self;
	[self addSubview:eventCollectionView];
	self.eventCollectionView = eventCollectionView;
		
	// Timeline overview
	UIView *overviewView = [[UIView alloc] initWithFrame:CGRectZero];
	[self addSubview:overviewView];
	self.overviewView = overviewView;
	
	// Timeline overview bar (not managed using autolayout)
	UIView *barView = [[UIView alloc] initWithFrame:CGRectZero];
	barView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
	barView.backgroundColor = [UIColor whiteColor];
	[overviewView addSubview:barView];
	self.barView = barView;
	
	// Disable implicit constraints for views managed with autolayout
	eventCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
	overviewView.translatesAutoresizingMaskIntoConstraints = NO;
	barView.translatesAutoresizingMaskIntoConstraints = NO;
	
	// Horizontal constraints in self
	[self addConstraint:[NSLayoutConstraint constraintWithItem:eventCollectionView
													 attribute:NSLayoutAttributeLeading
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeLeading
													multiplier:1.f
													  constant:0.f]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:eventCollectionView
													 attribute:NSLayoutAttributeTrailing
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeTrailing
													multiplier:1.f
													  constant:0.f]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:overviewView
													 attribute:NSLayoutAttributeLeading
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeLeading
													multiplier:1.f
													  constant:0.f]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:overviewView
													 attribute:NSLayoutAttributeTrailing
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeTrailing
													multiplier:1.f
													  constant:0.f]];
	
	// Vertical constraints in self
	[self addConstraint:[NSLayoutConstraint constraintWithItem:eventCollectionView
													 attribute:NSLayoutAttributeTop
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeTop
													multiplier:1.f
													  constant:RTSTimelineCollectionVerticalMargin]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:eventCollectionView
													 attribute:NSLayoutAttributeBottom
													 relatedBy:NSLayoutRelationEqual
														toItem:overviewView
													 attribute:NSLayoutAttributeTop
													multiplier:1.f
													  constant:0.f]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:overviewView
													 attribute:NSLayoutAttributeBottom
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeBottom
													multiplier:1.f
													  constant:0.f]];
	
	// Size constraints in self
	[self addConstraint:[NSLayoutConstraint constraintWithItem:eventCollectionView
													 attribute:NSLayoutAttributeHeight
													 relatedBy:NSLayoutRelationEqual
														toItem:overviewView
													 attribute:NSLayoutAttributeHeight
													multiplier:4.f
													  constant:0.f]];
	
	// Horizontal constraints in overviewView
	[overviewView addConstraint:[NSLayoutConstraint constraintWithItem:barView
															 attribute:NSLayoutAttributeLeading
															 relatedBy:NSLayoutRelationEqual
																toItem:overviewView
															 attribute:NSLayoutAttributeLeading
															multiplier:1.f
															  constant:RTSTimelineBarHorizontalMargin]];
	[overviewView addConstraint:[NSLayoutConstraint constraintWithItem:barView
															 attribute:NSLayoutAttributeTrailing
															 relatedBy:NSLayoutRelationEqual
																toItem:overviewView
															 attribute:NSLayoutAttributeTrailing
															multiplier:1.f
															  constant:-RTSTimelineBarHorizontalMargin]];
	
	// Vertical constraints in overviewView
	[overviewView addConstraint:[NSLayoutConstraint constraintWithItem:barView
															 attribute:NSLayoutAttributeCenterY
															 relatedBy:NSLayoutRelationEqual
																toItem:overviewView
															 attribute:NSLayoutAttributeCenterY
															multiplier:1.f
															  constant:0.f]];
	
	// Size constraints in overviewView
	[overviewView addConstraint:[NSLayoutConstraint constraintWithItem:barView
															 attribute:NSLayoutAttributeHeight
															 relatedBy:NSLayoutRelationEqual
																toItem:nil
															 attribute:NSLayoutAttributeNotAnAttribute
															multiplier:1.f
															  constant:RTSTimelineBarHeight]];
}
