//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSSegmentedTimelineView.h"

#import <AVFoundation/AVFoundation.h>
#import "RTSMediaPlayerController.h"
#import "RTSMediaSegment.h"
#import "RTSMediaSegmentsController.h"

// Function declarations
static void commonInit(RTSSegmentedTimelineView *self);

@interface RTSSegmentedTimelineView ()
@property (nonatomic, weak) UICollectionView *collectionView;
@end

@implementation RTSSegmentedTimelineView

#pragma mark - Object lifecycle

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

#pragma mark - Getters and setters

- (void)setItemWidth:(CGFloat)itemWidth
{
	_itemWidth = itemWidth;
	[self layoutIfNeeded];
}

- (void)setItemSpacing:(CGFloat)itemSpacing
{
	_itemSpacing = itemSpacing;
	[self layoutIfNeeded];
}

#pragma mark - Overrides

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
	collectionViewLayout.minimumLineSpacing = self.itemSpacing;
	collectionViewLayout.itemSize = CGSizeMake(self.itemWidth, CGRectGetHeight(self.collectionView.frame));
	[collectionViewLayout invalidateLayout];
}

#pragma mark - Cell reuse

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier
{
	[self.collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier
{
	[self.collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forSegment:(id<RTSMediaSegment>)segment
{
	NSInteger index = [self.segmentsController.visibleSegments indexOfObject:segment];
	if (index == NSNotFound) {
		return nil;
	}
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	return [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
}

#pragma mark - Data

- (void)reloadSegmentsForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSError *error))completionHandler
{
	[self.segmentsController reloadSegmentsForIdentifier:identifier completionHandler:^(NSError *error) {
		if (completionHandler) {
			completionHandler(error);
		}
		[self.collectionView reloadData];
	}];
}

#pragma mark - UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.segmentsController.visibleSegments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	id<RTSMediaSegment> segment = self.segmentsController.visibleSegments[indexPath.row];
	return [self.delegate timelineView:self cellForSegment:segment];
}

#pragma mark - UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	id<RTSMediaSegment> segment = self.segmentsController.visibleSegments[indexPath.row];
	[self scrollToSegment:segment animated:YES];
    [self.segmentsController playSegment:segment];
}

#pragma mark - UIScrollViewDelegate protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if ([self.delegate respondsToSelector:@selector(timelineViewDidScroll:)]) {
		[self.delegate timelineViewDidScroll:self];
	}
}

#pragma mark - Visible cells

// The -[UICollectionView indexPathsForVisibleCells] method is not reliable enough. Ask the layout instead
- (NSArray *) indexPathsForVisibleCells
{
	CGRect contentFrame = CGRectMake(self.collectionView.contentOffset.x,
									 self.collectionView.contentOffset.y,
									 CGRectGetWidth(self.collectionView.frame),
									 CGRectGetHeight(self.collectionView.frame));
	
	NSArray *layoutAttributesArray = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:contentFrame];
	
	NSMutableArray *indexPaths = [NSMutableArray array];
	for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesArray) {
		[indexPaths addObject:layoutAttributes.indexPath];
	}
	
	return [indexPaths sortedArrayUsingComparator:^(NSIndexPath *indexPath1, NSIndexPath *indexPath2) {
		return [indexPath1 compare:indexPath2];
	}];
}

- (NSArray *) visibleCells
{
	return self.collectionView.visibleCells;
}

- (void) scrollToSegment:(id<RTSMediaSegment>)segment animated:(BOOL)animated
{
	NSInteger segmentIndex = [self.segmentsController.visibleSegments indexOfObject:segment];
	if (segmentIndex == NSNotFound) {
		return;
	}
	
	[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:segmentIndex inSection:0]
								atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
										animated:animated];
}

- (void)scrollToSegmentAtTime:(CMTime)time animated:(BOOL)animated
{
    for (id<RTSMediaSegment> segment in self.segmentsController.visibleSegments) {
        if (CMTimeRangeContainsTime(segment.timeRange, time)) {
            [self scrollToSegment:segment animated:animated];
            break;
        }
    }
}

@end

#pragma mark - Functions

static void commonInit(RTSSegmentedTimelineView *self)
{
	UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
	collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	
	UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
	collectionView.backgroundColor = [UIColor clearColor];
	collectionView.alwaysBounceHorizontal = YES;
	collectionView.dataSource = self;
	collectionView.delegate = self;
	[self addSubview:collectionView];
	self.collectionView = collectionView;
	
	// Remove implicit constraints for views managed by autolayout
	collectionView.translatesAutoresizingMaskIntoConstraints = NO;
	
	// Constraints
	[self addConstraint:[NSLayoutConstraint constraintWithItem:collectionView
													 attribute:NSLayoutAttributeTop
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeTop
													multiplier:1.f
													  constant:0.f]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:collectionView
													 attribute:NSLayoutAttributeBottom
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeBottom
													multiplier:1.f
													  constant:0.f]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:collectionView
													 attribute:NSLayoutAttributeLeft
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeLeft
													multiplier:1.f
													  constant:0.f]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:collectionView
													 attribute:NSLayoutAttributeRight
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeRight
													multiplier:1.f
													  constant:0.f]];
	
	self.itemWidth = 60.f;
	self.itemSpacing = 4.f;
}
