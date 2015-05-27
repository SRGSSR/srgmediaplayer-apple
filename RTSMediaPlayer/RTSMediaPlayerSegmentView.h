//
//  Created by Samuel Défago on 22.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegment.h>
#import <RTSMediaPlayer/RTSMediaPlayerSegmentDataSource.h>

#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;

/**
 *  Common interface for views displaying segments. In general such views should be subclasses of RTSMediaPlayerSegmentView,
 *  but if this is not possible, have your view subclass conform to the RTSMediaPlayerSegmentView protocol, and use
 *  RTSMediaPlayerSegmentViewImplementation when implementing it
 */
@protocol RTSMediaPlayerSegmentView <NSObject>

/**
 *  This method is called when a view needs to be reloaded with segments. Implement this method accordingly, e.g.
 *  by reloading an associated collection or table view
 *
 *  @param segments The segments to be displayed (as an array of RTSMediaPlayerSegment objects)
 */
- (void) reloadWithSegments:(NSArray *)segments;

/**
 *  The time interval with which the view must be reloaded
 */
@property (nonatomic) NSTimeInterval reloadInterval;

@end

/**
 *  An abstract base class for views displaying segment information. Ensures retrieval of segments with the specified 
 *  reloadInterval (default is 30 seconds) when the player is running
 *
 *  To add such a view to a custom player layout, simply drag and drop an instance of the correspondig subclass 
 *  onto the player layout, and bind its mediaPlayerController and dataSource outlets. You can of course instantiate and
 *  configure the view programatically as well.
 *
 *  If you need to add segment support to an existing view and therefore cannot subclass RTSMediaPlayerSegmentView, 
 *  you can either:
 *    - Use a parent view inheriting from RTSMediaPlayerSegmentView, and install your existing view within it
 *    - Make your subclass conform to the RTSMediaPlayerSegmentView protocol, and use the RTSMediaPlayerSegmentViewImplementation
 *      in the underlying implementation
 */
@interface RTSMediaPlayerSegmentView : UIView <RTSMediaPlayerSegmentView>

/**
 *  The media player controller which the view is attached to
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

/**
 *  The segment data source
 */
@property (nonatomic, weak) IBOutlet id<RTSMediaPlayerSegmentDataSource> dataSource;

@end
