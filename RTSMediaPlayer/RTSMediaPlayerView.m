//
//  Created by Frédéric Humbert-Droz on 28/02/15.
//  Copyright (c) 2015 RTS. All rights reserved.
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
	return (AVPlayerLayer *)[self layer];
}

@end
