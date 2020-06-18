//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGTimePosition.h"

@interface SRGTimePosition ()

@property (nonatomic) CMTime time;
@property (nonatomic) CMTime toleranceBefore;
@property (nonatomic) CMTime toleranceAfter;

@end

@implementation SRGTimePosition

#pragma mark Class methods

+ (SRGTimePosition *)defaultPosition
{
    return [[self.class alloc] init];
}

+ (SRGTimePosition *)positionWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter
{
    return [[self.class alloc] initWithTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
}

#pragma mark Object lifecylce

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
    return [self initWithTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; time = %@; toleranceBefore = %@; toleranceAfter = %@>",
            self.class,
            self,
            @(CMTimeGetSeconds(self.time)),
            @(CMTimeGetSeconds(self.toleranceBefore)),
            @(CMTimeGetSeconds(self.toleranceAfter))];
}

@end
