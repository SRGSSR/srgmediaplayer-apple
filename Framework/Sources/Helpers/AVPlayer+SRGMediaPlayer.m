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

- (CGSize)srg_assetDimensions
{
    // TODO: See if AVAsset should be used for another reason (it has method to extract tracks of a given type, there
    //       must be some reason)
    NSPredicate *videoPredicate = [NSPredicate predicateWithBlock:^BOOL(AVPlayerItemTrack * _Nullable track, NSDictionary<NSString *, id> * _Nullable bindings) {
        return [track.assetTrack.mediaType isEqualToString:AVMediaTypeVideo];
    }];
    
    AVAssetTrack *assetTrack = [self.currentItem.tracks filteredArrayUsingPredicate:videoPredicate].firstObject.assetTrack;
    return CGSizeApplyAffineTransform(assetTrack.naturalSize, assetTrack.preferredTransform);
}

@end
