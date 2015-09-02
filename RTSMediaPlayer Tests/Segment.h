//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface Segment : NSObject <RTSMediaSegment>

- (instancetype) initWithName:(NSString *)name timeRange:(CMTimeRange)timeRange;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, getter=isBlocked) BOOL blocked;
@property (nonatomic, getter=isVisible) BOOL visible;

@end
