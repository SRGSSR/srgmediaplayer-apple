//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayerItem (SRGMediaPlayer)

/**
 *  Same as `-selectedMediaOptionInMediaSelectionGroup:`.
 */
// TODO: Remove when iOS 11 is the minimum deployment target
- (nullable AVMediaSelectionOption *)srgmediaplayer_selectedMediaOptionInMediaSelectionGroup:(AVMediaSelectionGroup *)mediaSelectionGroup;

/**
 *  Preferred option, see `-[AVAsset preferredMediaSelection]`.
 */
- (nullable AVMediaSelectionOption *)srgmediaplayer_preferredMediaOptionInMediaSelectionGroup:(AVMediaSelectionGroup *)mediaSelectionGroup;

@end

NS_ASSUME_NONNULL_END
