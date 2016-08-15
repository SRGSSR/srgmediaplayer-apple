//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSTimeSlider.h"

@class RTSMediaSegmentsController;
@protocol RTSMediaSegment;
@protocol RTSTimelineSliderDelegate;

/**
 *  A slider displaying segment start times along its track as small icons. The slider can be tapped at any point to 
 *  jump at the corresponding location.
 *
 *  To add a slider to a custom player layout, simply drag and drop an `RTSTimelineSlider` instance onto the player layout,
 *  and bind its segment controller and delegate outlets. You can of course also instantiate and configure the view 
 *  programmatically. Then call `reloadSegmentsWithIdentifier:completionHandler:` when you need to retrieve segments
 *  from the controller
 */
@interface RTSTimelineSlider : RTSTimeSlider

/**
 *  The controller which provides segments to the timeline
 */
@property (nonatomic, weak) IBOutlet RTSMediaSegmentsController *segmentsController;

/**
 *  The slider delegate
 */
@property (nonatomic, weak) IBOutlet id<RTSTimelineSliderDelegate> delegate;

/**
 *  Call this method to trigger a reload of the segments from the data source
 */
- (void)reloadSegmentsForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSError *error))completionHandler;

@end

/**
 *  Protocol describing events associated with the timeline
 */
@protocol RTSTimelineSliderDelegate <NSObject>

@optional

/**
 *  Return the icon to display in the timeline for a segment. If no icon is provided, a tick is displayed instead. The
 *  recommended size for the image is 15x15 points
 */
- (UIImage *)timelineSlider:(RTSTimelineSlider *)timelineSlider iconImageForSegment:(id<RTSMediaSegment>)segment;

@end
