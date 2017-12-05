//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVPlayer+SRGMediaPlayer.h"

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

@end
