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

- (void)countedSeekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL finished, NSInteger pendingSeekCount))completionHandler
{
    ++self.seekCount;
    [self seekToTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter completionHandler:^(BOOL finished) {
        --self.seekCount;
        completionHandler(finished, self.seekCount);
    }];
}

@end
