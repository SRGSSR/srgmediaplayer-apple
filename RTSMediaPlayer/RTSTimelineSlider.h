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

- (UIImage *) timelineSlider:(RTSTimelineSlider *)slider iconImageForEvent:(RTSTimelineEvent *)event;

@end
