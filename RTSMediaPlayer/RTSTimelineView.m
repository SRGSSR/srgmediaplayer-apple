//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineView.h"

#import "NSBundle+RTSMediaPlayer.h"
#import "RTSMediaPlayerController.h"
#import "RTSTimelineEventCollectionViewCell.h"

// Constants
static const CGFloat RTSTimelineBarHeight = 2.f;
static const CGFloat RTSTimelineEventViewSide = 8.f;
static const CGFloat RTSTimelineBarMargin = 2.f * RTSTimelineEventViewSide;

// Function declarations
static void commonInit(RTSTimelineView *self);

@interface RTSTimelineView ()

@property (nonatomic) NSArray *eventViews;

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
		[self reloadData];
	}];
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

- (void) layoutSubviews
{
	[super layoutSubviews];
	
	UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.eventCollectionView.collectionViewLayout;
	
	CGFloat cellSide = CGRectGetHeight(self.eventCollectionView.frame);
	collectionViewLayout.itemSize = CGSizeMake(cellSide, cellSide);
	[collectionViewLayout invalidateLayout];
}

#pragma mark - Display

- (void) reloadData
{
	for (UIView *eventView in self.eventViews)
	{
		[eventView removeFromSuperview];
	}
	
	NSInteger numberOfEvents = [self.dataSource numberOfEventsInTimelineView:self];
	if (numberOfEvents == 0)
	{
		return;
	}
	
	CMTimeRange currentTimeRange = [self currentTimeRange];
	if (CMTIMERANGE_IS_EMPTY(currentTimeRange))
	{
		return;
	}
	
	NSMutableArray *eventViews = [NSMutableArray array];
	for (NSInteger i = 0; i < numberOfEvents; ++i)
	{
		RTSTimelineEvent *event = [self.dataSource timelineView:self eventAtIndex:i];
		
		// Skip events not in the timeline
		if (CMTIME_COMPARE_INLINE(event.time, >, CMTimeRangeGetEnd(currentTimeRange)))
		{
			continue;
		}
		
		UIView *eventView = [[UIView alloc] initWithFrame:CGRectMake(roundf(RTSTimelineBarMargin + CMTimeGetSeconds(event.time) * (CGRectGetWidth(self.overviewView.frame) - 2.f * RTSTimelineBarMargin) / CMTimeGetSeconds(currentTimeRange.duration) - RTSTimelineEventViewSide / 2.f),
																	 roundf((CGRectGetHeight(self.overviewView.frame) - RTSTimelineEventViewSide) / 2.f),
																	 RTSTimelineEventViewSide,
																	 RTSTimelineEventViewSide)];
		eventView.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.6f];
		eventView.layer.cornerRadius = RTSTimelineEventViewSide / 2.f;
		eventView.layer.borderColor = [UIColor blackColor].CGColor;
		eventView.layer.borderWidth = 1.f;
		eventView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin| UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[self.overviewView addSubview:eventView];
		
		[eventViews addObject:eventView];
	}
	self.eventViews = [NSArray arrayWithArray:eventViews];
	
	[self.eventCollectionView reloadData];
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

#pragma mark - UICollectionViewDataSource protocol

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.dataSource numberOfEventsInTimelineView:self];
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([RTSTimelineEventCollectionViewCell class]) forIndexPath:indexPath];
}

#pragma mark - UICollectionViewDelegate protocol

- (void) collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{

}

@end

#pragma mark - Functions

static void commonInit(RTSTimelineView *self)
{
	// Collection view layout for easy navigation between events
	UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
	collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	
	// Collection view
	UICollectionView *eventCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
	eventCollectionView.alwaysBounceHorizontal = YES;
	eventCollectionView.dataSource = self;
	eventCollectionView.delegate = self;
	[self addSubview:eventCollectionView];
	self.eventCollectionView = eventCollectionView;
	
	// Cells
	NSString *className = NSStringFromClass([RTSTimelineEventCollectionViewCell class]);
	UINib *cellNib = [UINib nibWithNibName:className bundle:[NSBundle RTSMediaPlayerBundle]];
	[eventCollectionView registerNib:cellNib forCellWithReuseIdentifier:className];
	
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
													  constant:0.f]];
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
															  constant:RTSTimelineBarMargin]];
	[overviewView addConstraint:[NSLayoutConstraint constraintWithItem:barView
															 attribute:NSLayoutAttributeTrailing
															 relatedBy:NSLayoutRelationEqual
																toItem:overviewView
															 attribute:NSLayoutAttributeTrailing
															multiplier:1.f
															  constant:-RTSTimelineBarMargin]];
	
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
