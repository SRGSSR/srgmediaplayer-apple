//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPosition.h"

@interface SRGPosition ()

@property (nonatomic) CMTime time;
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

+ (SRGPosition *)positionAroundTime:(CMTime)time
{
    return [self positionWithTime:time toleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity];
}

+ (SRGPosition *)positionAroundTimeInSeconds:(NSTimeInterval)timeInSeconds
{
    return [self positionAroundTime:CMTimeMakeWithSeconds(timeInSeconds, NSEC_PER_SEC)];
}

+ (SRGPosition *)positionWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    return [[[self class] alloc] initWithTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
}

#pragma mark Object lifecycle

- (instancetype)initWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    if (self = [super init]) {
        self.time = CMTIME_IS_VALID(time) ? time : kCMTimeZero;
        self.toleranceBefore = CMTIME_IS_VALID(toleranceBefore) ? toleranceBefore : kCMTimeZero;
        self.toleranceAfter = CMTIME_IS_VALID(toleranceAfter) ? toleranceAfter : kCMTimeZero;
    }
    return self;
}

- (instancetype)init
{
    return [[SRGPosition alloc] initWithTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; time = %@; toleranceBefore = %@; toleranceAfter = %@>",
            [self class],
            self,
            @(CMTimeGetSeconds(self.time)),
            @(CMTimeGetSeconds(self.toleranceBefore)),
            @(CMTimeGetSeconds(self.toleranceAfter))];
}

@end
