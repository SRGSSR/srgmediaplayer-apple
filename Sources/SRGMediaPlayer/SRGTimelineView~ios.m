//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGTimelineView.h"

#import "SRGMediaPlayerController.h"

@import AVFoundation;

static void commonInit(SRGTimelineView *self);

@interface SRGTimelineView ()

@property (nonatomic, weak) UICollectionView *collectionView;

@end

@implementation SRGTimelineView

#pragma mark Object lifecycle

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

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    _mediaPlayerController = mediaPlayerController;
    [self reloadData];
}

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

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self reloadData];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    collectionViewLayout.minimumLineSpacing = self.itemSpacing;
    collectionViewLayout.itemSize = CGSizeMake(self.itemWidth, CGRectGetHeight(self.collectionView.frame));
    [collectionViewLayout invalidateLayout];
}

#pragma mark Cell reuse

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier
{
    [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier
{
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forSegment:(id<SRGSegment>)segment
{
    NSInteger index = [self.mediaPlayerController.visibleSegments indexOfObject:segment];
    NSAssert(index != NSNotFound, @"The segment must be found");
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    return [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
}

#pragma mark Data

- (void)reloadData
{
    [self.collectionView reloadData];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.mediaPlayerController.visibleSegments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<SRGSegment> segment = self.mediaPlayerController.visibleSegments[indexPath.row];
    return [self.delegate timelineView:self cellForSegment:segment];
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<SRGSegment> segment = self.mediaPlayerController.visibleSegments[indexPath.row];
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    if ([self.delegate respondsToSelector:@selector(timelineView:didSelectSegmentAtIndexPath:)]) {
        [self.delegate timelineView:self didSelectSegmentAtIndexPath:indexPath];
    }
    
    [self scrollToSegment:segment animated:YES];
}

#pragma mark UIScrollViewDelegate protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(timelineViewDidScroll:)]) {
        [self.delegate timelineViewDidScroll:self];
    }
}

#pragma mark Visible cells

- (NSArray<UICollectionViewCell *> *)visibleCells
{
    return self.collectionView.visibleCells;
}

- (void)scrollToSegment:(id<SRGSegment>)segment animated:(BOOL)animated
{
    if (! segment) {
        return;
    }
    
    NSInteger segmentIndex = [self.mediaPlayerController.visibleSegments indexOfObject:segment];
    if (segmentIndex == NSNotFound) {
        return;
    }
    
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:segmentIndex inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:animated];
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    
    for (NSInteger i = 0; i < 10; ++i) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(i * (self.itemWidth + self.itemSpacing),
                                                                0.f,
                                                                self.itemWidth,
                                                                CGRectGetHeight(self.frame))];
        view.backgroundColor = UIColor.darkGrayColor;
        [self addSubview:view];
    }
}

@end

#pragma mark Static functions

static void commonInit(SRGTimelineView *self)
{
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.alwaysBounceHorizontal = YES;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [self addSubview:collectionView];
    self.collectionView = collectionView;
    
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [collectionView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [collectionView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [collectionView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [collectionView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
    ]];
    
    self.itemWidth = 60.f;
    self.itemSpacing = 4.f;
}

#endif
