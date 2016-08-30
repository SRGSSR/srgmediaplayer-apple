//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

#pragma mark - Functions

static NSDateComponentsFormatter *SegmentDurationDateComponentsFormatter(void)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    return s_dateComponentsFormatter;
}

@interface Segment ()

@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic, copy) NSString *name;

@end

@implementation Segment

#pragma mark - Object lifecycle

- (instancetype)initWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    self = [super init];
    if (self) {
        self.timeRange = timeRange;
        self.blocked = NO;
        self.name = name;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name time:(CMTime)time
{
    return [self initWithName:name timeRange:CMTimeRangeMake(time, kCMTimeZero)];
}

- (instancetype)initWithName:(NSString *)name start:(NSTimeInterval)start duration:(NSTimeInterval)duration
{
    return [self initWithName:name timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(start, NSEC_PER_SEC), CMTimeMakeWithSeconds(duration, NSEC_PER_SEC))];
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithName:@"" timeRange:kCMTimeRangeZero];
}

#pragma mark - Getters and setters

- (NSURL *)thumbnailURL
{
    NSString *imageFilePath = [[NSBundle mainBundle] pathForResource:@"thumbnail-placeholder" ofType:@"png"];
    return [NSURL fileURLWithPath:imageFilePath];
}

- (NSString *)durationString
{
    return [SegmentDurationDateComponentsFormatter() stringFromTimeInterval:CMTimeGetSeconds(self.timeRange.duration)];
}

- (NSString *)timestampString
{
    NSString *startString = [SegmentDurationDateComponentsFormatter() stringFromTimeInterval:CMTimeGetSeconds(self.timeRange.start)];
    return [NSString stringWithFormat:@"%@ (%.0fs)", startString, CMTimeGetSeconds(self.timeRange.duration)];
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; start: %@; duration: %@; name: %@; blocked: %@>",
            [self class],
            self,
            @(CMTimeGetSeconds(self.timeRange.start)),
            @(CMTimeGetSeconds(self.timeRange.duration)),
            self.name,
            self.blocked ? @"YES" : @"NO"];
}

@end
