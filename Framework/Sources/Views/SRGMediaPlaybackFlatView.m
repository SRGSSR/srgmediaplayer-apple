//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlaybackFlatView.h"

#import <AVFoundation/AVFoundation.h>

@implementation SRGMediaPlaybackFlatView

#pragma mark Overrides

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

#pragma mark SRGMediaPlaybackView protocol

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}

- (void)setPlayer:(AVPlayer *)player withAssetDimensions:(CGSize)assetDimensions
{
    self.playerLayer.player = player;
}

- (AVPlayer *)player
{
    return self.playerLayer.player;
}

@end
