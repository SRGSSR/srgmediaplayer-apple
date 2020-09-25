//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import AVFoundation;
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Common protocol for playback views which can be displayed in `SRGMediaPlayerView`.
 */
@protocol SRGMediaPlaybackView <NSObject>

/**
 *  Called when the provided `AVPlayer` must be associated with the view.
 *
 *  @param assetDimensions The dimensions of the asset played. Might be `CGSizeZero`, e.g. if the asset has no
 *                         video tracks or when player is `nil`.
 */
- (void)setPlayer:(nullable AVPlayer *)player withAssetDimensions:(CGSize)assetDimensions;

/**
 *  The `AVPlayer` associated with the view.
 */
@property (nonatomic, readonly) AVPlayer *player;

/**
 *  The `AVPlayerLayer` provided by the view, if any.
 *
 *  @discusssion If the method returns `nil`, picture in picture will not be available for the playback view.
 */
@property (nonatomic, readonly, nullable) AVPlayerLayer *playerLayer;

@end

NS_ASSUME_NONNULL_END
