//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayer (SRGMediaPlayer)

/**
 *  Attempt to play the media immediately if possible (iOS 10), otherwise normally.
 */
- (void)srg_playImmediatelyIfPossible;

/**
 *  Return the dimensions for the currently played item.
 *
 *  @discussion If nothing is being played or if the media has only an audio track, returns `CGSizeZero`.
 */
@property (nonatomic, readonly) CGSize srg_assetDimensions;

@end

NS_ASSUME_NONNULL_END
