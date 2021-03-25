//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVPlayerItem+SRGMediaPlayer.h"

@implementation AVPlayerItem (SRGMediaPlayer)

/**
 *  Same as `-selectedMediaOptionInMediaSelectionGroup:`.
 */
// TODO: Remove when iOS 11 is the minimum deployment target
- (AVMediaSelectionOption *)srgmediaplayer_selectedMediaOptionInMediaSelectionGroup:(AVMediaSelectionGroup *)mediaSelectionGroup
{
#if TARGET_OS_TV
    return [self.currentMediaSelection selectedMediaOptionInMediaSelectionGroup:mediaSelectionGroup];
#else
#if !TARGET_OS_MACCATALYST
    if (@available(iOS 11, *)) {
#endif
        return [self.currentMediaSelection selectedMediaOptionInMediaSelectionGroup:mediaSelectionGroup];
#if !TARGET_OS_MACCATALYST
    }
    else {
        return [self selectedMediaOptionInMediaSelectionGroup:mediaSelectionGroup];
    }
#endif
#endif
}

@end
