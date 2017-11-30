//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

#import <AVFoundation/AVFoundation.h>

@interface SRGMediaPlayerView ()

@property (nonatomic) AVPlayer *player;

@end

@implementation SRGMediaPlayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}

- (void)setPlayer:(AVPlayer *)player
{
    _player = player;
    
    self.playerLayer.player = player;
}

@end
