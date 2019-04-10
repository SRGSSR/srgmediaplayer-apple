//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ViewController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface ViewController ()

@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;
@property (nonatomic) IBOutlet SRGMediaPlayerView *mediaPlayerView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mediaPlayerView.viewMode = SRGMediaPlayerViewModeMonoscopic;
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/360/2017/2_Gothard_360_full_f_8414077-,301k,701k,1201k,2001k,.mp4.csmil/master.m3u8"];
    [self.mediaPlayerController playURL:URL];
}

@end
