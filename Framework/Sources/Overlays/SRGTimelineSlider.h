//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"
#import "SRGTimeSlider.h"

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@protocol SRGTimelineSliderDelegate;

/**
 *  A slider displaying segment start times along its track as small icons. The slider can be tapped at any point to
 *  jump at the corresponding location.
 *
 *  To add a slider to a custom player layout, simply drag and drop an `SRGTimelineSlider` instance onto the player layout,
 *  and bind its segment controller and delegate outlets. You can of course also instantiate and configure the view
 *  programmatically. Then call ` reloadSegmentsWithIdentifier:completionHandler:` when you need to retrieve segments
 *  from the controller
 */
@interface SRGTimelineSlider : SRGTimeSlider

/**
 *  The slider delegate
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGTimelineSliderDelegate> delegate;

- (void)reloadData;

@end

/**
 *  Protocol describing events associated with the timeline
 */
@protocol SRGTimelineSliderDelegate <NSObject>

@optional

/**
 *  Return the icon to display in the timeline for a segment. If no icon is provided, a tick is displayed instead. The
 *  recommended size for the image is 15x15 points
 */
- (UIImage *)timelineSlider:(SRGTimelineSlider *)timelineSlider iconImageForSegment:(id<SRGSegment>)segment;

@end

NS_ASSUME_NONNULL_END
