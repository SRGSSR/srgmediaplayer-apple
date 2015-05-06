//
//  Created by Samuel Défago on 06.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerController.h>
#import <RTSMediaPlayer/RTSTimeSlider.h>
#import <RTSMediaPlayer/RTSTimelineView.h>

@protocol RTSTimelineSliderDataSource;

@interface RTSTimelineSlider : RTSTimeSlider

@property (nonatomic, weak) IBOutlet RTSTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet id<RTSTimelineSliderDataSource> dataSource;

@end

@protocol RTSTimelineSliderDataSource <NSObject>

@optional

/**
 *  Return the icon to be displayed on the overview. If this method is not implemented, a white dot is displayed by
 *  default. Images should have the recommended size of 8x8 pixels
 *
 *  @param timelineSlider The slider
 *  @param event          The event for which the icon must be returned
 *
 *  @return The image to use
 */
- (UIImage *) timelineSlider:(RTSTimelineSlider *)slider iconImageForEvent:(RTSTimelineEvent *)event;

@end
