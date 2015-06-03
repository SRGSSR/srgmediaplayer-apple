//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "RTSTimelineView.h"

/**
 *  Private interface for implementation purposes
 */
@interface RTSTimelineView (Private)

/**
 *  Return the index paths of all cells currently within the area of the view
 *
 *  @return the index paths as an array of NSIndexPath objects
 */
- (NSArray *)indexPathsForVisibleCells;

@end
