//
//  ViewController.m
//  SRGMediaPlayer-temp-demo
//
//  Created by Samuel Défago on 25/08/16.
//  Copyright © 2016 SRG. All rights reserved.
//

#import "ViewController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface ViewController ()

@property (nonatomic) RTSMediaPlayerController *playerController;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.playerController = [[RTSMediaPlayerController alloc] init];
	
	self.playerController.view.frame = self.view.bounds;
	self.playerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:self.playerController.view];
	
	[self.playerController playURL:[NSURL URLWithString:@"http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4"]];
}

@end
