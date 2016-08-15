//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

// Forward declarations
@class RTSMediaSegmentsController;
@protocol RTSSegmentedTimelineViewDelegate;
@protocol RTSMediaSegment;

/**
 *  A view displaying segments associated with a stream as a linear collection of cells
 *
 *  To add a timeline to a custom player layout, simply drag and drop an `RTSTimelineView` onto the player layout,
 *  and bind its segment controller and delegate outlets. You can of course instantiate and configure the view
 *  programatically as well. Then call `-reloadSegmentsWithIdentifier:completionHandler:` when you need to retrieve
 *  segments from the controller
 *
 *  Customisation of timeline cells is achieved through subclassing of `UICollectionViewCell`, exactly like a usual
 *  `UICollectionView`
 */
@interface RTSSegmentedTimelineView : UIView <UICollectionViewDataSource, UICollectionViewDelegate>

/**
 *  The controller which provides segments to the timeline
 */
@property (nonatomic, weak) IBOutlet RTSMediaSegmentsController *segmentsController;

/**
 *  The timeline delegate
 */
@property (nonatomic, weak) IBOutlet id<RTSSegmentedTimelineViewDelegate> delegate;

/**
 *  The width of cells within the timeline. Defaults to 60
 */
@property (nonatomic) IBInspectable CGFloat itemWidth;

/**
 * The spacing between cells in the timeline. Defaults to 4
 */
@property (nonatomic) IBInspectable CGFloat itemSpacing;

/**
 *  Register cell classes for reuse. Cells must be subclasses of `UICollectionViewCell` and can be instantiated either
 *  programmatically or using a nib. For more information about cell reuse, refer to `UICollectionView` documentation.
 *  To dequeue cells from the reuse queue, call -dequeueReusableCellWithReuseIdentifier:forSegment:
 */
- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;

/**
 *  Call this method to trigger a reload of the segments from the data source, for the specified identifier. An optional
 *  completion handler block can be provided
 */
- (void)reloadSegmentsForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSError *error))completionHandler;

/**
 *  Dequeue a reusable cell for a given segment
 *
 *  @param identifier The cell identifier (must be appropriately set for the cell)
 *  @param segment    The segment for which a cell must be dequeued
 */
- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forSegment:(id<RTSMediaSegment>)segment;

/**
 * Return the list of currently visible cells
 */
- (NSArray *)visibleCells;

/**
 *  Scroll to make the specified segment visible (does nothing if the segment does not belong to the visible segments
 *  of the segmentsController.
 */
- (void)scrollToSegment:(id<RTSMediaSegment>)segment animated:(BOOL)animated;

@end

/**
 *  Timeline delegate protocol
 */
@protocol RTSSegmentedTimelineViewDelegate <NSObject>

/**
 *  Return the cell to be displayed for a segment. You should call `-dequeueReusableCellWithReuseIdentifier:forSegment:`
 *  within the implementation of this method to reuse existing cells and improve scrolling smoothness
 *
 *  @param timelineView The timeline
 *  @param segment      The segment for which the cell must be returned
 *
 *  @return The cell to use
 */
- (UICollectionViewCell *)timelineView:(RTSSegmentedTimelineView *)timelineView cellForSegment:(id<RTSMediaSegment>)segment;

@optional

/**
 * Called when the timeline sees one of its visible segment selected by the user.
 */
- (void)timelineView:(RTSSegmentedTimelineView *)timelineView didSelectSegmentAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Called when the timeline has been scrolled interactively
 */
- (void)timelineViewDidScroll:(RTSSegmentedTimelineView *)timelineView;

@end
