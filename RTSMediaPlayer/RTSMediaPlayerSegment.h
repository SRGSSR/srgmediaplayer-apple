//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

/**
 *  Describe a media segment
 */
@interface RTSMediaPlayerSegment : NSObject

/**
 *  Create a segment between two times
 *
 *  @param startTime startTime The segment start time
 *  @param endTime   endTime The segment end time
 *
 *  @return <#return value description#>
 */
- (instancetype) initWithStartTime:(CMTime)startTime endTime:(CMTime)endTime;

/**
 *  Segment start and end times
 */
@property (nonatomic, readonly) CMTime startTime;
@property (nonatomic, readonly) CMTime endTime;

/**
 *  An optional title
 */
@property (nonatomic, copy) NSString *title;

/**
 *  An optional image URL
 */
@property (nonatomic, copy) NSURL *imageURL;

@end
