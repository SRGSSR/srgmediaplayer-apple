//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayerItem (SRGMediaPlayer)

- (NSArray<AVAssetTrack *> *)srg_assetTracksWithMediaType:(AVMediaType)mediaType;

@end

NS_ASSUME_NONNULL_END
