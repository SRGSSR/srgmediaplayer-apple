//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

#pragma mark - Functions

@interface Segment ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic) CMTimeRange srg_timeRange;
@property (nonatomic, getter=srg_isBlocked) BOOL srg_blocked;
@property (nonatomic, getter=srg_isHidden) BOOL srg_hidden;

@end

@implementation Segment

#pragma mark Object lifecycle

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.name = dictionary[@"name"];
        self.srg_blocked = [dictionary[@"blocked"] boolValue];
        self.srg_hidden = [dictionary[@"hidden"] boolValue];
        
        NSTimeInterval startTime = [dictionary[@"startTime"] doubleValue] / 1000.;
        NSTimeInterval duration = [dictionary[@"duration"] doubleValue] / 1000.;
        
        self.srg_timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, NSEC_PER_SEC),
                                             CMTimeMakeWithSeconds(duration, NSEC_PER_SEC));
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithDictionary:@{}];
}

#pragma mark Getters and setters

- (NSURL *)thumbnailURL
{
    NSString *imageFilePath = [[NSBundle mainBundle] pathForResource:@"thumbnail-placeholder" ofType:@"png"];
    return [NSURL fileURLWithPath:imageFilePath];
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; start: %@; duration: %@; name: %@; blocked: %@; hidden: %@>",
            [self class],
            self,
            @(CMTimeGetSeconds(self.srg_timeRange.start)),
            @(CMTimeGetSeconds(self.srg_timeRange.duration)),
            self.name,
            self.srg_blocked ? @"YES" : @"NO",
            self.srg_hidden ? @"YES" : @"NO"];
}

@end
