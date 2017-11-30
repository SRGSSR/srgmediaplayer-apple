//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerFlatView.h"

@implementation SRGMediaPlayerFlatView

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
    self.playerLayer.player = player;
}

- (AVPlayer *)player
{
    return self.playerLayer.player;
}

@end
