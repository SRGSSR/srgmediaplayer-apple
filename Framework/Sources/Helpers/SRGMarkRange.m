//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMarkRange.h"

@interface SRGMarkRange ()

@property (nonatomic) SRGMark *fromMark;
@property (nonatomic) SRGMark *toMark;

@end

@implementation SRGMarkRange

#pragma mark Class methods

+ (SRGMarkRange *)rangeFromMark:(SRGMark *)fromMark toMark:(SRGMark *)toMark
{
    return [[self.class alloc] initWithFromMark:fromMark toMark:toMark];
}

#pragma mark Object lifecycle

- (instancetype)initWithFromMark:(SRGMark *)fromMark toMark:(SRGMark *)toMark
{
    if (self = [super init]) {
        self.fromMark = fromMark;
        self.toMark = toMark;
    }
    return self;
}

#pragma mark Equality

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:self.class]) {
        return NO;
    }
    
    SRGMarkRange *otherMarkRange = object;
    return [self.fromMark isEqual:otherMarkRange.fromMark] && [self.toMark isEqual:otherMarkRange.toMark];
    
}

- (NSUInteger)hash
{
    return [NSString stringWithFormat:@"%@_%@", @(self.fromMark.hash), @(self.toMark.hash)].hash;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; fromMark = %@; toMark = %@>",
            self.class,
            self,
            self.fromMark,
            self.toMark];
}

@end

@implementation SRGMarkRange (Convenience)

+ (SRGMarkRange *)rangeFromTime:(CMTime)fromTime toTime:(CMTime)toTime
{
    return [self rangeFromMark:[SRGMark markAtTime:fromTime] toMark:[SRGMark markAtTime:toTime]];
}

+ (SRGMarkRange *)rangeFromTimeRange:(CMTimeRange)timeRange
{
    return [self rangeFromTime:timeRange.start toTime:CMTimeRangeGetEnd(timeRange)];
}

+ (SRGMarkRange *)rangeFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    return [self rangeFromMark:[SRGMark markAtDate:fromDate] toMark:[SRGMark markAtDate:toDate]];
}

@end
