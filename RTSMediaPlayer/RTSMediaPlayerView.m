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

#pragma mark - Player

- (AVPlayer *) player
{
	return [(AVPlayerLayer *)self.layer player];
}

- (void) setPlayer:(AVPlayer *)player
{
	[(AVPlayerLayer *)self.layer setPlayer:player];
}


@end
