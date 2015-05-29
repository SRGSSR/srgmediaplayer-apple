//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

/**
 *  Describe a media segment
 */
@protocol RTSMediaPlayerSegment <NSObject>

/**
 *  Segment start and end times (might be identical)
 */
@property (nonatomic, readonly) CMTimeRange segmentTimeRange;

@property (nonatomic, readonly, getter=isBlocked) BOOL blocked;
@property (nonatomic, readonly, getter=isVisible) BOOL visible;

@end
