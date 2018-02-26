//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVPlayer+SRGMediaPlayer.h"

#import <objc/runtime.h>

static void *s_seekCountKey = &s_seekCountKey;

@implementation AVPlayer (SRGMediaPlayer)

// TODO: Remove when iOS 10 is the minimum required version.
- (void)srg_playImmediatelyIfPossible
{
    if ([self respondsToSelector:@selector(playImmediatelyAtRate:)]) {
        [self playImmediatelyAtRate:1.f];
    }
    else {
        [self play];
    }
}

- (void)srg_countedSeekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL finished, NSInteger pendingSeekCount))completionHandler
{
    NSInteger seekCount = [objc_getAssociatedObject(self, s_seekCountKey) integerValue] + 1;
    objc_setAssociatedObject(self, s_seekCountKey, @(seekCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self seekToTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter completionHandler:^(BOOL finished) {
        NSInteger pendingSeekCount = [objc_getAssociatedObject(self, s_seekCountKey) integerValue] - 1;
        objc_setAssociatedObject(self, s_seekCountKey, @(pendingSeekCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        completionHandler(finished, pendingSeekCount);
    }];
}

@end
