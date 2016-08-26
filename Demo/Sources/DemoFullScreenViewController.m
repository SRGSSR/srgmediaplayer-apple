//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemoFullScreenViewController.h"
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface DemoFullScreenViewController ()

@property (nonatomic, weak) id<RTSMediaPlayerControllerDataSource> dataSource;
@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, strong) IBOutlet SRGMediaPlayerController *mediaPlayerController;

@end

@implementation DemoFullScreenViewController

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
