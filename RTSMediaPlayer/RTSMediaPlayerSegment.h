//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

@interface RTSMediaPlayerSegment : NSObject

- (instancetype) initWithStartTime:(CMTime)startTime endTime:(CMTime)endTime;

@property (nonatomic, readonly) CMTime startTime;
@property (nonatomic, readonly) CMTime endTime;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSURL *imageURL;

@end
