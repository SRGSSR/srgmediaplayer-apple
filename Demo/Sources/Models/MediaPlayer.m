//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayer.h"

@interface MediaPlayer ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic) Class playerClass;

@end

@implementation MediaPlayer

+ (MediaPlayer *)mediaPlayerWithName:(NSString *)name class:(Class)playerClass
{
    return [[[self class] alloc] initWithName:name class:playerClass];
}

- (instancetype)initWithName:(NSString *)name class:(Class)playerClass
{
    if (self = [super init]) {
        self.name = name;
        self.playerClass = playerClass;
    }
    return self;
}

@end
