//
//  Created by Frédéric Humbert-Droz on 06/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RTSMediaPlayer/RTSOverlayViewProtocol.h>

@class RTSMediaPlayerController;

@interface RTSVolumeView : UIView <RTSOverlayViewProtocol>

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@end
