//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaSegment.h"

@interface MediaSegment ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic) SRGMarkRange *srg_markRange;
@property (nonatomic, getter=srg_isBlocked) BOOL srg_blocked;
@property (nonatomic, getter=srg_isHidden) BOOL srg_hidden;

@end

@implementation MediaSegment

#pragma mark Object lifecycle

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.name = dictionary[@"name"];
        self.srg_blocked = [dictionary[@"blocked"] boolValue];
        self.srg_hidden = [dictionary[@"hidden"] boolValue];
        
        NSTimeInterval startTime = [dictionary[@"startTime"] doubleValue] / 1000.;
        NSTimeInterval duration = [dictionary[@"duration"] doubleValue] / 1000.;
        
        self.srg_markRange = [SRGMarkRange rangeFromTime:CMTimeMakeWithSeconds(startTime, NSEC_PER_SEC)
                                                  toTime:CMTimeMakeWithSeconds(startTime + duration, NSEC_PER_SEC)];
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithDictionary:@{}];
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; range = %@; name: %@; blocked = %@; hidden = %@>",
            self.class,
            self,
            self.srg_markRange,
            self.name,
            self.srg_blocked ? @"YES" : @"NO",
            self.srg_hidden ? @"YES" : @"NO"];
}

@end
