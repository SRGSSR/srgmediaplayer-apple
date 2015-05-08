//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  Represent an event to be displayed by an RTSTimelineView. Subclass if your events carry more information which
 *  needs to be displayed in the timeline
 */
@interface RTSTimelineEvent : NSObject

/**
 *  Instantiate an event with the specific location in time (relative to the start of the stream)
 */
- (instancetype) initWithTime:(CMTime)time NS_DESIGNATED_INITIALIZER;

/**
 *  The event time
 */
@property (nonatomic, readonly) CMTime time;

/**
 *  An optional icon to use in the timeline slider (recommended size is 15 x 15 points)
 */
@property (nonatomic) UIImage *iconImage;

@end

@interface RTSTimelineEvent (UnavailableMethods)

- (instancetype) init NS_UNAVAILABLE;

@end
