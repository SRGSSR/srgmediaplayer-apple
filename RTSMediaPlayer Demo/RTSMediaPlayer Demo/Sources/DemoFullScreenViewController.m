//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "DemoFullScreenViewController.h"
#import <SRGMediaPlayer/SRGMediaPlayer.h>

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
