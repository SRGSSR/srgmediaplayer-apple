//
//  Created by Frédéric Humbert-Droz on 28/02/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface RTSMediaPlayerView : UIView

@property (strong) AVPlayer *player;

@property (readonly) AVPlayerLayer *playerLayer;

@end
