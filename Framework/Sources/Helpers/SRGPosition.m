//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPosition.h"

@interface SRGPosition ()

@property (nonatomic) CMTime time;
@property (nonatomic) NSDate *date;
@property (nonatomic) CMTime toleranceBefore;
@property (nonatomic) CMTime toleranceAfter;

@end

@implementation SRGPosition

#pragma mark Class methods

+ (SRGPosition *)defaultPosition
{
    return [self positionWithTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

+ (SRGPosition *)positionAtTime:(CMTime)time
{
    return [self positionWithTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

+ (SRGPosition *)positionAtTimeInSeconds:(NSTimeInterval)timeInSeconds
{
    return [self positionAtTime:CMTimeMakeWithSeconds(timeInSeconds, NSEC_PER_SEC)];
}

+ (SRGPosition *)positionAtDate:(NSDate *)date
{
    return [self positionWithDate:date toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

+ (SRGPosition *)positionAroundTime:(CMTime)time
{
    return [self positionWithTime:time toleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity];
}

+ (SRGPosition *)positionAroundTimeInSeconds:(NSTimeInterval)timeInSeconds
{
    return [self positionAroundTime:CMTimeMakeWithSeconds(timeInSeconds, NSEC_PER_SEC)];
}

+ (SRGPosition *)positionAroundDate:(NSDate *)date
{
    return [self positionWithDate:date toleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity];
}

+ (SRGPosition *)positionBeforeTime:(CMTime)time
{
    return [self positionWithTime:time toleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimeZero];
}

+ (SRGPosition *)positionBeforeTimeInSeconds:(NSTimeInterval)timeInSeconds
{
    return [self positionBeforeTime:CMTimeMakeWithSeconds(timeInSeconds, NSEC_PER_SEC)];
}

+ (SRGPosition *)positionBeforeDate:(NSDate *)date
{
    return [self positionWithDate:date toleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimeZero];
}

+ (SRGPosition *)positionAfterTime:(CMTime)time
{
    return [self positionWithTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimePositiveInfinity];
}

+ (SRGPosition *)positionAfterTimeInSeconds:(NSTimeInterval)timeInSeconds
{
    return [self positionAfterTime:CMTimeMakeWithSeconds(timeInSeconds, NSEC_PER_SEC)];
}

+ (SRGPosition *)positionAfterDate:(NSDate *)date
{
    return [self positionWithDate:date toleranceBefore:kCMTimeZero toleranceAfter:kCMTimePositiveInfinity];
}

+ (SRGPosition *)positionWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    return [[self.class alloc] initWithTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
}

+ (SRGPosition *)positionWithDate:(NSDate *)date toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    return [[self.class alloc] initWithDate:date toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
}

#pragma mark Object lifecycle

- (instancetype)initWithTime:(CMTime)time date:(NSDate *)date toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
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
        
        self.toleranceBefore = CMTIME_IS_VALID(toleranceBefore) ? toleranceBefore : kCMTimeZero;
        self.toleranceAfter = CMTIME_IS_VALID(toleranceAfter) ? toleranceAfter : kCMTimeZero;
    }
    return self;
}

- (instancetype)initWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    return [self initWithTime:time date:nil toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
}

- (instancetype)initWithDate:(NSDate *)date toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    return [self initWithTime:kCMTimeZero date:date toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
}

- (instancetype)init
{
    return [[SRGPosition alloc] initWithTime:kCMTimeZero date:nil toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; time = %@; date = %@; toleranceBefore = %@; toleranceAfter = %@>",
            self.class,
            self,
            @(CMTimeGetSeconds(self.time)),
            self.date,
            @(CMTimeGetSeconds(self.toleranceBefore)),
            @(CMTimeGetSeconds(self.toleranceAfter))];
}

@end
