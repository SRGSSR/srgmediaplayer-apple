//
//  Created by Samuel Défago on 22.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegment.h>
#import <RTSMediaPlayer/RTSMediaPlayerSegmentDataSource.h>

#import <UIKit/UIKit.h>

/**
 *  An abstract base class for views displaying segment information.
 *
 *  To add such a view to a custom player layout, simply drag and drop an instance of the correspondig subclass 
 *  onto the player layout, and bind its dataSource outlet. You can of course instantiate and configure the view 
 *  programatically as well. Then call -reloadSegmentsWithIdentifier: when you need to retrieve segments from 
 *  the data source
 */
@interface RTSMediaPlayerSegmentView : UIView

/**
 *  The segment data source
 */
@property (nonatomic, weak) IBOutlet id<RTSMediaPlayerSegmentDataSource> dataSource;

/**
 *  Call this method to trigger a reload of the segments from the data source
 */
- (void) reloadSegmentsForIdentifier:(NSString *)identifier;

@end

@interface RTSMediaPlayerSegmentView (SubclassingHooks)

/**
 *  This method is called when the view needs to be reloaded with segments. Implement this method accordingly in your
 *  subclass, e.g. by reloading an associated collection or table view
 *
 *  @param segments The segments to be displayed (as an array objects conforming to the RTSMediaPlayerSegment protocol)
 */
- (void) reloadWithSegments:(NSArray *)segments;

@end
