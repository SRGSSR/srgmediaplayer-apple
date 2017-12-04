//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

#import "AVPlayer+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "SRGMediaPlayback360View.h"
#import "SRGMediaPlaybackFlatView.h"

#import <libextobjc/libextobjc.h>

static CMMotionManager *s_motionManager = nil;

@interface SRGMediaPlayerView ()

@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) UIView<SRGMediaPlaybackView> *playbackView;

@end

@implementation SRGMediaPlayerView

+ (CMMotionManager *)motionManager
{
    return s_motionManager;
}

+ (void)setMotionManager:(CMMotionManager *)motionManager
{
    s_motionManager = motionManager;
}

- (void)setPlayer:(AVPlayer *)player
{
    [_player removeObserver:self keyPath:@keypath(_player.currentItem.tracks)];
    
    _player = player;
    
    [player srg_addMainThreadObserver:self keyPath:@keypath(player.currentItem.tracks) options:0 block:^(MAKVONotification *notification) {
        [self updatePlaybackViewWithPlayer:player];
    }];
    
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
    
    CGSize assetDimensions = player.srg_assetDimensions;
    if (! CGSizeEqualToSize(assetDimensions, CGSizeZero)) {
        Class playbackViewClass = Nil;
        
        // 360 videos are provided in equirectangular format (2:1)
        // See https://www.360rize.com/2017/04/5-things-you-should-know-about-360-video-resolution/
        CGFloat ratio = assetDimensions.width / assetDimensions.height;
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
        
        if (self.playbackView.player != player) {
            self.playbackView.player = player;
        }
    }
}

@end
