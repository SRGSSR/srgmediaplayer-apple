//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVPlayer+SRGMediaPlayer.h"

#import <objc/runtime.h>

static void *s_seekRequestsCountKey = &s_seekRequestsCountKey;

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
    NSInteger requestCount = [objc_getAssociatedObject(self, s_seekRequestsCountKey) integerValue] + 1;
    objc_setAssociatedObject(self, s_seekRequestsCountKey, @(requestCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self seekToTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter completionHandler:^(BOOL finished) {
        NSInteger pendingSeekCount = [objc_getAssociatedObject(self, s_seekRequestsCountKey) integerValue] - 1;
        objc_setAssociatedObject(self, s_seekRequestsCountKey, @(pendingSeekCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        completionHandler(finished, pendingSeekCount);
    }];
}

@end
