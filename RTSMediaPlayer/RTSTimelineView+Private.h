//
//  Created by Samuel Défago on 06.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
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
- (NSArray *) indexPathsForVisibleCells;

@end
