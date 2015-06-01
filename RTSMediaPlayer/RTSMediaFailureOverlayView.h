//
//  Created by Frédéric Humbert-Droz on 16/05/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RTSMediaPlayer/RTSMediaPlayerController.h>

@interface RTSMediaFailureOverlayView : UIView

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end
