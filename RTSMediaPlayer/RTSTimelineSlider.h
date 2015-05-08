//
//  Created by Samuel Défago on 06.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerController.h>
#import <RTSMediaPlayer/RTSTimeSlider.h>
#import <RTSMediaPlayer/RTSTimelineView.h>

/**
 *  A slider displaying events along its track as small icons. The slider can be tapped at any point to jump at the 
 *  corresponding location.
 *
 *  The slider is meant to be associated with a timeline, which it displays events from. As the timeline is scrolled,
 *  icons matching visible cells in the timeline are automatically highlighted.
 *
 *  To add a slider to a custom player layout, simply drag and drop an RTSTimelineSlider onto the player layout,
 *  and bind its timelineView outlet to an associated timeline. You can of course also instantiate the view 
 *  programmatically.
 */
@interface RTSTimelineSlider : RTSTimeSlider

/**
 *  The associated timeline, from which events are automatically retrieved
 */
@property (nonatomic, weak) IBOutlet RTSTimelineView *timelineView;

@end
