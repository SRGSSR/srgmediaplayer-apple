//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineEvent.h"

#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;
@class RTSTimelineView;

@protocol RTSTimelineViewDataSource <NSObject>

- (NSInteger) numberOfEventsInTimelineView:(RTSTimelineView *)timelineView;
- (RTSTimelineEvent *) timelineView:(RTSTimelineView *)timelineView eventAtIndex:(NSInteger)index;

@end

@interface RTSTimelineView : UIView

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) id<RTSTimelineViewDataSource> dataSource;

- (void) reloadData;

@end
