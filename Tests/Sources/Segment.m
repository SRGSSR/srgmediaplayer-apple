//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic) SRGMarkRange *srg_markRange;
@property (nonatomic, getter=srg_isBlocked) BOOL srg_blocked;
@property (nonatomic, getter=srg_isHidden) BOOL srg_hidden;

@end

@implementation Segment

#pragma mark Class methods

+ (Segment *)segmentWithMarkRange:(SRGMarkRange *)markRange
{
    return [[self.class alloc] initWithMarkRange:markRange];
}

+ (Segment *)segmentWithTimeRange:(CMTimeRange)timeRange
{
    SRGMarkRange *markRange = [SRGMarkRange rangeFromTimeRange:timeRange];
    return [self segmentWithMarkRange:markRange];
}

+ (Segment *)blockedSegmentWithTimeRange:(CMTimeRange)timeRange
{
    SRGMarkRange *markRange = [SRGMarkRange rangeFromTimeRange:timeRange];
    Segment *segment = [self segmentWithMarkRange:markRange];
    segment.srg_blocked = YES;
    return segment;
}

+ (Segment *)hiddenSegmentWithTimeRange:(CMTimeRange)timeRange
{
    SRGMarkRange *markRange = [SRGMarkRange rangeFromTimeRange:timeRange];
    Segment *segment = [self segmentWithMarkRange:markRange];
    segment.srg_hidden = YES;
    return segment;
}

+ (Segment *)segmentFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    SRGMarkRange *markRange = [SRGMarkRange rangeFromDate:fromDate toDate:toDate];
    return [self segmentWithMarkRange:markRange];
}

#pragma mark Object lifecycle

- (instancetype)initWithMarkRange:(SRGMarkRange *)markRange
{
    if (self = [super init]) {
        self.srg_markRange = markRange;
    }
    return self;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; range = %@>",
            self.class,
            self,
            self.srg_markRange];
}

@end
