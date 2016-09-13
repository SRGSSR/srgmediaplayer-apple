//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic, getter=isBlocked) BOOL blocked;

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
    segment.blocked = YES;
    return segment;
}

#pragma mark Object lifecycle

- (instancetype)initWithTimeRange:(CMTimeRange)timeRange
{
    if (self = [super init]) {
        self.timeRange = timeRange;
    }
    return self;
}

#pragma mark Getters and setters

- (BOOL)isHidden
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
            @(CMTimeGetSeconds(self.timeRange.start)),
            @(CMTimeGetSeconds(self.timeRange.duration))];
}

@end
