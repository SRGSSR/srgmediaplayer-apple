//
//  RTSMediaPlayerViewController.m
//  RTSMediaPlayer
//
//  Created by Frédéric Humbert-Droz on 03/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerViewController.h"
#import <RTSMediaPlayer/RTSMediaPlayerController.h>

@interface RTSMediaPlayerViewController ()
@property RTSMediaPlayerController *mediaPlayerController;
@end

@implementation RTSMediaPlayerViewController

- (instancetype) initWithContentURL:(NSURL *)contentURL
{
	NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"RTSMediaPlayer" withExtension:@"bundle"];
	if (!(self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleWithURL:bundleURL]]))
		return nil;
	
	_mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentURL:contentURL];
	
	return self;
}

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"RTSMediaPlayer" withExtension:@"bundle"];
	if (!(self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleWithURL:bundleURL]]))
		return nil;
	
	_mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:identifier dataSource:dataSource];
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self.mediaPlayerController attachPlayerToView:self.view];
	[self.mediaPlayerController play];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleDefault;
}

- (IBAction) togglePlayPause:(id)sender
{
	if (self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying)
	{
		[self.mediaPlayerController pause];
	}
	else
	{
		[self.mediaPlayerController play];
	}
}

- (IBAction) dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
