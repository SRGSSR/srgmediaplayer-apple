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
    AVMediaSelection *currentMediaSelection = self.currentMediaSelection;
    return [currentMediaSelection selectedMediaOptionInMediaSelectionGroup:mediaSelectionGroup];
#else
    if (@available(iOS 11, *)) {
        AVMediaSelection *currentMediaSelection = self.currentMediaSelection;
        return [currentMediaSelection selectedMediaOptionInMediaSelectionGroup:mediaSelectionGroup];
    }
    else {
        return [self selectedMediaOptionInMediaSelectionGroup:mediaSelectionGroup];
    }
#endif
}

@end
