//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegmentDataSource.h>

#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;
@protocol RTSTimelineViewDelegate;

/**
 *  A view displaying segments associated with a stream as a linear collection of cells
 *
 *  To add a timeline to a custom player layout, simply drag and drop an RTSTimelineView onto the player layout,
 *  and bind its mediaPlayerController, dataSource and delegate outlets.
 *
 *  Customisation of timeline cells is achieved through subclassing of UICollectionViewCell, exactly like a usual 
 *  UICollectionView. Segments are represented by the RTSMediaPlayerSegment class, which only carry a few pieces of
 *  information. If you need more information to be displayed on a cell (e.g. a title or a thumbnail), subclass 
 *  RTSMediaPlayerSegment to add the data you need, and use this information when returning cells from your data source.
 */
@interface RTSTimelineView : UIView <RTSMediaPlayerSegmentDisplayer, UICollectionViewDataSource, UICollectionViewDelegate>

/**
 *  The width of cells within the timeline. Defaults to 60
 */
@property (nonatomic) CGFloat itemWidth;

/**
 * The spacing between cells in the timeline. Defaults to 4
 */
@property (nonatomic) CGFloat itemSpacing;

/**
 *  The media player controller to which the timeline is bound
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

/**
 *  Register cell classes for reuse. Cells must be subclasses of UICollectionViewCell and can be instantiated either
 *  programmatically or using a nib. For more information about cell reuse, refer to UICollectionView documentation
 */
- (void) registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
- (void) registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;

/**
 *  Dequeue a reusable cell for a given segment
 *
 *  @param identifier The cell identifier (must be appropriately set for the cell)
 *  @param segment    The segment for which a cell must be dequeued
 */
- (id) dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forSegment:(RTSMediaPlayerSegment *)segment;

/**
 *  The timeline data source
 */
@property (nonatomic, weak) IBOutlet id<RTSMediaPlayerSegmentDataSource> dataSource;

/**
 *  The timeline delegate
 */
@property (nonatomic, weak) IBOutlet id<RTSTimelineViewDelegate> delegate;

@end

/**
 *  Timeline delegate protocol
 */
@protocol RTSTimelineViewDelegate <NSObject>

/**
 *  Return the cell to be displayed for a segment. You should call -dequeueReusableCellWithReuseIdentifier:forSegment:
 *  within the implementation of this method to reuse existing cells and improve scrolling smoothness
 *
 *  @param timelineView The timeline
 *  @param segment      The segment for which the cell must be returned
 *
 *  @return The cell to use
 */
- (UICollectionViewCell *) timelineView:(RTSTimelineView *)timelineView cellForSegment:(RTSMediaPlayerSegment *)segment;

@optional

/**
 *  This method is called when the user taps on a cell. If the method is not implemented, the default action is to
 *  play the video starting from the segment start time
 *
 *  @param timelineView The timeline
 *  @param segment      The segment which has been selected
 */
- (void) timelineView:(RTSTimelineView *)timelineView didSelectSegment:(RTSMediaPlayerSegment *)segment;

@end
