//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVPlayerItem+SRGMediaPlayer.h"

#import <libextobjc/libextobjc.h>

@implementation AVPlayerItem (SRGMediaPlayer)

- (NSArray<AVAssetTrack *> *)srg_assetTracksWithMediaType:(AVMediaType)mediaType
{
    // Tracks cannot be relably retrieved from assets for network content.
    // For more information, refer to https://stackoverflow.com/questions/6242131/using-avassetreader-to-read-stream-from-a-remote-asset
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVPlayerItemTrack * _Nullable track, NSDictionary<NSString *, id> * _Nullable bindings) {
        return [track.assetTrack.mediaType isEqualToString:mediaType];
    }];
    
    // TODO: See https://github.com/SRGSSR/srgmediaplayer-ios/issues/63. Should do something else, and probably with the
    //       asset
    NSArray<AVPlayerItemTrack *> *tracks = [self.tracks filteredArrayUsingPredicate:predicate];
    return [tracks valueForKeyPath:@keypath(AVPlayerItemTrack.new, assetTrack)] ?: @[];
}

@end
