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
