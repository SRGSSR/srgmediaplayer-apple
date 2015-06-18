//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>
#import <RTSMediaPlayer/RTSMediaPlayer.h>

@interface Segment : NSObject <RTSMediaSegment>

- (instancetype) initWithName:(NSString *)name timeRange:(CMTimeRange)timeRange;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, getter=isBlocked) BOOL blocked;
@property (nonatomic, getter=isVisible) BOOL visible;

@end
