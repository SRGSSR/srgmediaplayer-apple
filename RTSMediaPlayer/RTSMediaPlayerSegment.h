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
@protocol RTSMediaPlayerSegment <NSObject>

/**
 *  Segment start and end times (might be identical)
 */
@property (nonatomic, readonly) CMTimeRange segmentTimeRange;

/**
 *  An icon to use in the timeline slider (recommended size is 15 x 15 points)
 */
@property (nonatomic, readonly) UIImage *segmentIconImage;

@end
