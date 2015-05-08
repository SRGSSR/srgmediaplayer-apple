//
//  Created by Samuel Défago on 06.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerController.h>
#import <RTSMediaPlayer/RTSTimeSlider.h>
#import <RTSMediaPlayer/RTSTimelineView.h>

/**
 *  A slider displaying events along its track. The slider can be tapped at any point to seek at the corresponding
 *  location. If the
 *
 */
@interface RTSTimelineSlider : RTSTimeSlider

@property (nonatomic, weak) IBOutlet RTSTimelineView *timelineView;

@end
