//
//  Created by Samuel Défago on 06.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerController.h>
#import <RTSMediaPlayer/RTSTimelineEvent.h>
#import <UIKit/UIKit.h>

@protocol RTSTimelineOverviewDataSource;

@interface RTSTimelineOverview : UIView

@property (nonatomic) NSArray *events;

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet id<RTSTimelineOverviewDataSource> dataSource;

@end

@protocol RTSTimelineOverviewDataSource <NSObject>

- (UIImage *) timelineOverview:(RTSTimelineOverview *)timelineOverview iconImageForEvent:(RTSTimelineEvent *)event;

@end
