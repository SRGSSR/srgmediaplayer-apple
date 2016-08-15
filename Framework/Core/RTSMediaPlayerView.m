//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation RTSMediaPlayerView

+ (Class) layerClass
{
	return [AVPlayerLayer class];
}

- (AVPlayer *) player
{
	return self.playerLayer.player;
}

- (void) setPlayer:(AVPlayer *)player
{
	self.playerLayer.player = player;
}

- (AVPlayerLayer *) playerLayer
{
	return (AVPlayerLayer *)self.layer;
}

@end
