//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  Represent an event to be displayed by an RTSTimelineView. Subclass if your timeline needs to display more
 *  information
 */
@interface RTSTimelineEvent : NSObject

/**
 *  Instantiate an event with the specific location in time (relative to the start of the stream)
 */
- (instancetype) initWithTime:(CMTime)time;

/**
 *  The event time
 */
@property (nonatomic, readonly) CMTime time;

@end
