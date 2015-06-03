//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
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
