//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ViewController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface ViewController ()

@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
}

@end
