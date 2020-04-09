//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMark.h"

@interface SRGMark ()

@property (nonatomic) CMTime time;
@property (nonatomic) NSDate *date;

@end

@implementation SRGMark

#pragma mark Class methods

+ (SRGMark *)markAtTime:(CMTime)time
{
    return [[self.class alloc] initWithTime:time date:nil];
}

+ (SRGMark *)markAtTimeInSeconds:(NSTimeInterval)timeInSeconds
{
    return [[self.class alloc] initWithTime:CMTimeMakeWithSeconds(timeInSeconds, NSEC_PER_SEC) date:nil];
}

+ (SRGMark *)markAtDate:(NSDate *)date
{
    return [[self.class alloc] initWithTime:kCMTimeZero date:date];
}

#pragma mark Object lifecycle

- (instancetype)initWithTime:(CMTime)time date:(NSDate *)date
{
    if (self = [super init]) {
        if (date) {
            self.time = kCMTimeZero;
            self.date = date;
        }
        else {
            self.time = CMTIME_IS_VALID(time) ? time : kCMTimeZero;
            self.date = nil;
        }
    }
    return self;
}

#pragma mark Equality

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:self.class]) {
        return NO;
    }
    
    SRGMark *otherMark = object;
    if (self.date) {
        return [self.date isEqualToDate:otherMark.date];
    }
    else {
        return CMTIME_COMPARE_INLINE(self.time, ==, otherMark.time);
    }
}

- (NSUInteger)hash
{
    if (self.date) {
        return self.date.hash;
    }
    else {
        return @(CMTimeGetSeconds(self.time)).hash;
    }
}

#pragma mark Description

- (NSString *)description
{
    if (self.date) {
        return [NSString stringWithFormat:@"<%@: %p; date = %@>",
                self.class,
                self,
                self.date];
        
    }
    else {
        return [NSString stringWithFormat:@"<%@: %p; time (seconds) = %@",
                self.class,
                self,
                @(CMTimeGetSeconds(self.time))];
    }
}

@end
