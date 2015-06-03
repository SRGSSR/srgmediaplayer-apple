//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <UIKit/UIKit.h>
#import <RTSMediaPlayer/RTSMediaPlayerController.h>

@interface RTSMediaFailureOverlayView : UIView

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end
