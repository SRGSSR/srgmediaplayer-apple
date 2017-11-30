//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

#import "SRGMediaPlayback360View.h"
#import "SRGMediaPlaybackFlatView.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@interface SRGMediaPlayerView ()

@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) UIView<SRGMediaPlaybackView> *playbackView;

@end

@implementation SRGMediaPlayerView

- (void)setPlayer:(AVPlayer *)player
{
    if (_player) {
        [_player removeObserver:self keyPath:@keypath(_player.currentItem.tracks)];
    }
    
    _player = player;
    
    if (player) {
        @weakify(player)
        [player addObserver:self keyPath:@keypath(player.currentItem.tracks) options:0 block:^(MAKVONotification *notification) {
            @strongify(player)
            [self updatePlaybackViewWithPlayer:player];
        }];
    }
    
    [self updatePlaybackViewWithPlayer:player];
}

- (AVPlayerLayer *)playerLayer
{
    return self.playbackView.playerLayer;
}

- (void)updatePlaybackViewWithPlayer:(AVPlayer *)player
{
    if (! player) {
        [self.playbackView removeFromSuperview];
        return;
    }
    
    // TODO: See if AVAsset should be used for another reason (it has method to extract tracks of a given type, there
    //       must be some reason)
    NSPredicate *videoPredicate = [NSPredicate predicateWithBlock:^BOOL(AVPlayerItemTrack * _Nullable track, NSDictionary<NSString *, id> * _Nullable bindings) {
        return [track.assetTrack.mediaType isEqualToString:AVMediaTypeVideo];
    }];
    
    AVAssetTrack *assetTrack = [player.currentItem.tracks filteredArrayUsingPredicate:videoPredicate].firstObject.assetTrack;
    if (assetTrack) {
        CGSize size = CGSizeApplyAffineTransform(assetTrack.naturalSize, assetTrack.preferredTransform);
        CGFloat ratio = size.width / size.height;
        
        Class playbackViewClass = Nil;
        
        // 360 videos are provided in equirectangular format (2:1)
        // See https://www.360rize.com/2017/04/5-things-you-should-know-about-360-video-resolution/
        if (ratio == 2.f) {
            playbackViewClass = [SRGMediaPlayback360View class];
        }
        else {
            playbackViewClass = [SRGMediaPlaybackFlatView class];
        }
        
        if (! [self.playbackView isKindOfClass:playbackViewClass]) {
            [self.playbackView removeFromSuperview];
            
            UIView<SRGMediaPlaybackView> *playbackView = [[playbackViewClass alloc] initWithFrame:self.bounds];
            playbackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:playbackView];
            self.playbackView = playbackView;
        }
        
        self.playbackView.player = player;
    }
}

@end
