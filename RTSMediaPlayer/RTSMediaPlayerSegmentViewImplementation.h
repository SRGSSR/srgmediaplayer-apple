//
//  Created by Samuel Défago on 22.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegmentDataSource.h>
#import <Foundation/Foundation.h>

@class RTSMediaPlayerController;
@protocol RTSMediaPlayerSegmentView;

/**
 *  Implementation helper class for views displaying segments but which cannot inherit from RTSMediaPlayerSegmentView
 *  (see RTSMediaPlayerSegmentView.h for more information)
 */
@interface RTSMediaPlayerSegmentViewImplementation : NSObject

/**
 *  Create the implementation helper associated with the view. Best created in the view initialization method
 *
 *  @param view The view to which the implementation is associated
 */
- (instancetype) initWithView:(UIView<RTSMediaPlayerSegmentView> *)view;

/**
 *  The media player controller to which the implementation must be associated. A time observer is automatically
 *  registered with it, fired at a reload interval controlled by the reloadInterval property, triggering segment
 *  reload
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

/**
 *  The data source from which segments are periodically retrieved
 */
@property (nonatomic, weak) IBOutlet id<RTSMediaPlayerSegmentDataSource> dataSource;

/**
 *  The interval at which the associated view must be reloaded with segments (default is 30 seconds)
 */
@property (nonatomic) NSTimeInterval reloadInterval;

@end

@interface RTSMediaPlayerSegmentViewImplementation (UnavailableMethods)

- (instancetype) init NS_UNAVAILABLE;

@end
