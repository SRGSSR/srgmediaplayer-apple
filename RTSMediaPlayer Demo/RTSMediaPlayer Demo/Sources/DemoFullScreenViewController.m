//
//  Created by Cédric Luthi on 27.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "DemoFullScreenViewController.h"
#import <RTSMediaPlayer/RTSMediaPlayer.h>

@interface DemoFullScreenViewController ()

@property (nonatomic, weak) id<RTSMediaPlayerControllerDataSource> dataSource;
@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, strong) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@end

@implementation DemoFullScreenViewController

- (IBAction)dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
