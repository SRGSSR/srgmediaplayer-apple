//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  Describe a media segment. Can also represent a point in time when segment start and end times are
 *  identical
 */
@interface RTSMediaPlayerSegment : NSObject

/**
 *  Create a segment between two times
 *
 *  @param startTime startTime The segment start time
 *  @param endTime   endTime The segment end time
 */
- (instancetype) initWithStartTime:(CMTime)startTime endTime:(CMTime)endTime NS_DESIGNATED_INITIALIZER;

/**
 *  Segment start and end times (might be identical)
 */
@property (nonatomic, readonly) CMTime startTime;
@property (nonatomic, readonly) CMTime endTime;

/**
 *  An optional icon to use in the timeline slider (recommended size is 15 x 15 points)
 */
@property (nonatomic) UIImage *iconImage;

@end

@interface RTSMediaPlayerSegment (UnavailableMethods)

- (instancetype) init NS_UNAVAILABLE;

@end
