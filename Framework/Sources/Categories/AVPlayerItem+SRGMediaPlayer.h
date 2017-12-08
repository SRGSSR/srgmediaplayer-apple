//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayerItem (SRGMediaPlayer)

/**
 *  Return the current list of asset tracks having the specified media type. If none is found, the returned
 *  array is empty.
 */
- (NSArray<AVAssetTrack *> *)srg_assetTracksWithMediaType:(AVMediaType)mediaType;

@end

NS_ASSUME_NONNULL_END
