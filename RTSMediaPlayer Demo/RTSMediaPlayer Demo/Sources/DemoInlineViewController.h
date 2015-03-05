//
//  Created by Cédric Luthi on 27.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <RTSMediaPlayer/RTSMediaPlayer.h>

@interface DemoInlineViewController : UIViewController <RTSMediaPlayerControllerDataSource>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

@property (nonatomic, strong) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, strong) NSURL *mediaURL;

@end
