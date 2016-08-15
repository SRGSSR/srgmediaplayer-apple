//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSSegmentedTimelineView.h"

/**
 *  Private interface for implementation purposes
 */
@interface RTSSegmentedTimelineView (Private)

/**
 *  Return the index paths of all cells currently within the area of the view
 *
 *  @return the index paths as an array of NSIndexPath objects
 */
- (NSArray *)indexPathsForVisibleCells;

@end
