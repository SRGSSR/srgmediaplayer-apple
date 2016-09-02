//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic, getter=isBlocked) BOOL blocked;

@end

@implementation Segment

+ (Segment *)segmentWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    return [[[self class] alloc] initWithName:name timeRange:timeRange];
}

+ (Segment *)blockedSegmentWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    Segment *segment = [[[self class] alloc] initWithName:name timeRange:timeRange];
    segment.blocked = YES;
    return segment;
}

- (instancetype)initWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    if (self = [super init]) {
        self.name = name;
        self.timeRange = timeRange;
    }
    return self;
}

@end
