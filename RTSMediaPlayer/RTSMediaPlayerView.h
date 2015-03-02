//
//  RTSMediaPlayerView.h
//  RTSMediaPlayer
//
//  Created by Frédéric Humbert-Droz on 28/02/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVPlayer;

@interface RTSMediaPlayerView : UIView

- (void)setPlayer:(AVPlayer *)player;

@end
