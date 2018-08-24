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

+ (SRGPosition *)precisePositionAtTime:(CMTime)time
{
    return [self positionWithTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

+ (SRGPosition *)imprecisePositionAroundTime:(CMTime)time
{
    return [self positionWithTime:time toleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity];
}

+ (SRGPosition *)positionWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    return [[[self class] alloc] initWithTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
}

#pragma mark Object lifecycle

- (instancetype)initWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    if (self = [super init]) {
        self.time = time;
        self.toleranceBefore = toleranceBefore;
        self.toleranceAfter = toleranceAfter;
    }
    return self;
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
