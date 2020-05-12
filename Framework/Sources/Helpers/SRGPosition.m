//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPosition.h"

@interface SRGPosition ()

@property (nonatomic) SRGMark *mark;

@property (nonatomic) CMTime toleranceBefore;
@property (nonatomic) CMTime toleranceAfter;

@end

@implementation SRGPosition

#pragma mark Class methods

+ (SRGPosition *)defaultPosition
{
    return [self positionWithTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

+ (SRGPosition *)positionWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    SRGMark *mark = [SRGMark markAtTime:time];
    return [[self.class alloc] initWithMark:mark toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
}

+ (SRGPosition *)positionWithDate:(NSDate *)date toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    SRGMark *mark = [SRGMark markAtDate:date];
    return [[self.class alloc] initWithMark:mark toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
}

+ (SRGPosition *)positionWithMark:(SRGMark *)mark toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    return [[self.class alloc] initWithMark:mark toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
}

#pragma mark Object lifecycle

- (instancetype)initWithMark:(SRGMark *)mark toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    NSParameterAssert(mark);
    
    if (self = [super init]) {
        self.mark = mark;
        self.toleranceBefore = CMTIME_IS_VALID(toleranceBefore) ? toleranceBefore : kCMTimeZero;
        self.toleranceAfter = CMTIME_IS_VALID(toleranceAfter) ? toleranceAfter : kCMTimeZero;
    }
    return self;
}

- (instancetype)init
{
    return [[SRGPosition alloc] initWithMark:nil toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark Getters and setters

- (CMTime)time
{
    return [self.mark timeForMediaPlayerController:nil];
}

- (NSDate *)date
{
    return self.mark.date;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; mark = %@; toleranceBefore = %@; toleranceAfter = %@>",
            self.class,
            self,
            self.mark,
            @(CMTimeGetSeconds(self.toleranceBefore)),
            @(CMTimeGetSeconds(self.toleranceAfter))];
}

@end

@implementation SRGPosition (Exact)

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

+ (SRGPosition *)positionAtMark:(SRGMark *)mark
{
    return [self positionWithMark:mark toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

@end

@implementation SRGPosition (Around)

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

+ (SRGPosition *)positionAroundMark:(SRGMark *)mark
{
    return [self positionWithMark:mark toleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity];
}

@end

@implementation SRGPosition (Before)

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

+ (SRGPosition *)positionBeforeMark:(SRGMark *)mark
{
    return [self positionWithMark:mark toleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimeZero];
}

@end

@implementation SRGPosition (After)

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

+ (SRGPosition *)positionAfterMark:(SRGMark *)mark
{
    return [self positionWithMark:mark toleranceBefore:kCMTimeZero toleranceAfter:kCMTimePositiveInfinity];
}

@end
