//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic) CMTimeRange srg_timeRange;
@property (nonatomic, getter=srg_isBlocked) BOOL srg_blocked;

@end

@implementation Segment

#pragma mark Class methods

+ (Segment *)segmentWithTimeRange:(CMTimeRange)timeRange
{
    return [[[self class] alloc] initWithTimeRange:timeRange];
}

+ (Segment *)blockedSegmentWithTimeRange:(CMTimeRange)timeRange
{
    Segment *segment = [[[self class] alloc] initWithTimeRange:timeRange];
    segment.srg_blocked = YES;
    return segment;
}

#pragma mark Object lifecycle

- (instancetype)initWithTimeRange:(CMTimeRange)timeRange
{
    if (self = [super init]) {
        self.srg_timeRange = timeRange;
    }
    return self;
}

#pragma mark Getters and setters

- (BOOL)srg_isHidden
{
    // NO need to test hidden segments in unit tests, those are only for use by UI overlays
    return NO;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; startTime: %@; duration: %@>",
            [self class],
            self,
            @(CMTimeGetSeconds(self.srg_timeRange.start)),
            @(CMTimeGetSeconds(self.srg_timeRange.duration))];
}

@end
