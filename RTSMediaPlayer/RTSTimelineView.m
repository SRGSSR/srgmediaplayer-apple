//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineView.h"

#import "RTSMediaPlayerController.h"
#import "RTSTimeSlider.h"

// Constants
//static const CGFloat RTSTimelineEventIconSide = 8.f;
static const CGFloat RTSTimelineCollectionVerticalMargin = 4.f;
static const CGFloat RTSTimelineBarHorizontalMargin = 10.f;

// Function declarations
static void commonInit(RTSTimelineView *self);

@interface RTSTimelineView ()

@property (nonatomic, weak) UICollectionView *eventCollectionView;
@property (nonatomic, weak) RTSTimeSlider *timeSlider;

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
	
	self.timeSlider.mediaPlayerController = mediaPlayerController;
}

- (void) setTimeLeftValueLabel:(UILabel *)timeLeftValueLabel
{
	self.timeSlider.timeLeftValueLabel = timeLeftValueLabel;
}

- (UILabel *) timeLeftValueLabel
{
	return self.timeSlider.timeLeftValueLabel;
}

- (void) setValueLabel:(UILabel *)valueLabel
{
	self.timeSlider.valueLabel = valueLabel;
}

- (UILabel *) valueLabel
{
	return self.timeSlider.valueLabel;
}

- (void) setEvents:(NSArray *)events
{
	_events = events;
	
	[self.eventCollectionView reloadData];
	[self reloadTimeline];
}

- (void) setItemWidth:(CGFloat)itemWidth
{
	_itemWidth = itemWidth;
	
	[self layoutIfNeeded];
}

- (void) setItemSpacing:(CGFloat)itemSpacing
{
	_itemSpacing = itemSpacing;
	
	[self layoutIfNeeded];
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
	collectionViewLayout.minimumLineSpacing = self.itemSpacing;
	collectionViewLayout.itemSize = CGSizeMake(self.itemWidth, CGRectGetHeight(self.eventCollectionView.frame));
	[collectionViewLayout invalidateLayout];
	
	[self highlightVisibleEventIconsAnimated:NO];
}

#pragma mark - Display

- (void) reloadTimeline
{

}

- (void) highlightVisibleEventIconsAnimated:(BOOL)animated
{

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

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self highlightVisibleEventIconsAnimated:YES];
}

// The -[UICollectionView indexPathsForVisibleCells] method is not reliable enough. Ask the layout instead
- (NSArray *)indexPathsForVisibleCells
{
	CGRect contentFrame = CGRectMake(self.eventCollectionView.contentOffset.x,
									 self.eventCollectionView.contentOffset.y,
									 CGRectGetWidth(self.eventCollectionView.frame),
									 CGRectGetHeight(self.eventCollectionView.frame));
	NSArray *layoutAttributesArray = [self.eventCollectionView.collectionViewLayout layoutAttributesForElementsInRect:contentFrame];
	
	NSMutableArray *indexPaths = [NSMutableArray array];
	for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesArray)
	{
		[indexPaths addObject:layoutAttributes.indexPath];
	}
	
	return [indexPaths sortedArrayUsingComparator:^NSComparisonResult (NSIndexPath *indexPath1, NSIndexPath *indexPath2) {
		return [indexPath1 compare:indexPath2];
	}];
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
	
	// Collection view
	UICollectionView *eventCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
	eventCollectionView.backgroundColor = [UIColor clearColor];
	eventCollectionView.alwaysBounceHorizontal = YES;
	eventCollectionView.dataSource = self;
	eventCollectionView.delegate = self;
	[self addSubview:eventCollectionView];
	self.eventCollectionView = eventCollectionView;
		
	// Slider
	RTSTimeSlider *timeSlider = [[RTSTimeSlider alloc] initWithFrame:CGRectZero];
	[self addSubview:timeSlider];
	self.timeSlider = timeSlider;
	
	// Disable implicit constraints for views managed with autolayout
	eventCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
	timeSlider.translatesAutoresizingMaskIntoConstraints = NO;
	
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
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:timeSlider
													 attribute:NSLayoutAttributeLeading
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeLeading
													multiplier:1.f
													  constant:RTSTimelineBarHorizontalMargin]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:timeSlider
													 attribute:NSLayoutAttributeTrailing
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeTrailing
													multiplier:1.f
													  constant:-RTSTimelineBarHorizontalMargin]];
	
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
														toItem:timeSlider
													 attribute:NSLayoutAttributeTop
													multiplier:1.f
													  constant:0.f]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:timeSlider
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
														toItem:timeSlider
													 attribute:NSLayoutAttributeHeight
													multiplier:4.f
													  constant:0.f]];
	
	self.itemWidth = 60.f;
	self.itemSpacing = 4.f;
}
