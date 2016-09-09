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

#pragma mark Class methods

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

#pragma mark Object lifecycle

- (instancetype)initWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    if (self = [super init]) {
        self.name = name;
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
    return [NSString stringWithFormat:@"<%@: %p; name: %@; startTime: %@; duration: %@>",
            [self class],
            self,
            self.name,
            @(CMTimeGetSeconds(self.timeRange.start)),
            @(CMTimeGetSeconds(self.timeRange.duration))];
}

@end
