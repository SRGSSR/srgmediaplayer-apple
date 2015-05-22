//
//  Created by Samuel Défago on 06.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegmentDataSource.h>
#import <RTSMediaPlayer/RTSTimeSlider.h>

@class RTSMediaPlayerController;

/**
 *  A slider displaying segment start times along its track as small icons. The slider can be tapped at any point to 
 *  jump at the corresponding location.
 *
 *  To add a slider to a custom player layout, simply drag and drop an RTSTimelineSlider onto the player layout,
 *  and bind its timelineView outlet to an associated timeline. You can of course also instantiate the view 
 *  programmatically.
 */
@interface RTSTimelineSlider : RTSTimeSlider <RTSMediaPlayerSegmentDisplayer>

/**
 *  The timeline data source
 */
@property (nonatomic, weak) IBOutlet id<RTSMediaPlayerSegmentDataSource> dataSource;

@end
