//
//  ViewController.m
//  SRGMediaPlayer-temp-demo
//
//  Created by Samuel Défago on 25/08/16.
//  Copyright © 2016 SRG. All rights reserved.
//

#import "ViewController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

static void *s_kvoContext = &s_kvoContext;

@interface ViewController ()

@property (nonatomic) RTSMediaPlayerController *playerController;

@end

@implementation ViewController

- (void)dealloc
{
	self.playerController = nil;
}

- (void)setPlayerController:(RTSMediaPlayerController *)playerController
{
	[_playerController removeObserver:self forKeyPath:@"playbackState"];
	_playerController = playerController;
	[playerController addObserver:self forKeyPath:@"playbackState" options:0 context:s_kvoContext];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.playerController = [[RTSMediaPlayerController alloc] init];
	
	self.playerController.view.frame = self.view.bounds;
	self.playerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view insertSubview:self.playerController.view atIndex:0];
	
	[self.playerController playURL:[NSURL URLWithString:@"http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4"]];
}

- (IBAction)togglePlayPause:(id)sender
{
	[self.playerController togglePlayPause];
}

- (IBAction)seek:(id)sender
{
	[self.playerController seekToTime:CMTimeAdd(self.playerController.player.currentTime, CMTimeMakeWithSeconds(10, 1)) completionHandler:^(BOOL finished) {
		NSLog(@"Finished: %@", finished ? @"YES" : @"NO");
	}];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	if (context == s_kvoContext) {
		NSLog(@"Playback state = %@", @(self.playerController.playbackState));
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
