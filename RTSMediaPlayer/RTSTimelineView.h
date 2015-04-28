//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;
@class RTSTimelineView;

@protocol RTSTimelineViewDataSource <NSObject>

- (void) numberOfEventsInTimelineView:(RTSTimelineView *)timelineView;

@optional
- (NSString *) timelineView:(RTSTimelineView *)timelineView titleForEventAtIndex:(NSUInteger)index;
- (UIImage *) timelineView:(RTSTimelineView *)timelineView imageForEventAtIndex:(NSUInteger)index;

@end

@interface RTSTimelineView : UIView

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) id<RTSTimelineViewDataSource> dataSource;

@end
