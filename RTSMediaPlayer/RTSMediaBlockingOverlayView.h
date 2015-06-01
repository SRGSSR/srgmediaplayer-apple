//
//  RTSMediaBlockingOverlayView.h
//  RTSMediaPlayer
//
//  Created by Cédric Foellmi on 01/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RTSMediaPlayer/RTSMediaPlayerController.h>

@interface RTSMediaBlockingOverlayView : UIView

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end
