//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPlayer.h"

@interface SRGPlayer ()

@property (nonatomic) NSInteger seekCount;

@end

@implementation SRGPlayer

- (BOOL)isSeeking
{
    return self.seekCount != 0;
}

// TODO: Remove when iOS / tvOS 10 is the minimum required version.
- (void)playImmediatelyIfPossible
{
    if (@available(iOS 10, tvOS 10, *)) {
        [self playImmediatelyAtRate:1.f];
    }
    else {
        [self play];
    }
}

- (void)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL finished))completionHandler
{
    ++self.seekCount;
    [super seekToTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter completionHandler:^(BOOL finished) {
        --self.seekCount;
        completionHandler(finished);
    }];
}

@end
