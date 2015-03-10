//
//  Created by Frédéric Humbert-Droz on 03/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerViewController.h"

#import <RTSMediaPlayer/RTSMediaPlayerControllerDataSource.h>
#import <RTSMediaPlayer/RTSMediaPlayerController.h>

@interface RTSMediaPlayerViewController () <RTSMediaPlayerControllerDataSource>

@property (nonatomic, weak) id<RTSMediaPlayerControllerDataSource> dataSource;
@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, strong) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@end

@implementation RTSMediaPlayerViewController

- (instancetype) initWithContentURL:(NSURL *)contentURL
{
	return [self initWithContentIdentifier:contentURL.absoluteString dataSource:self];
}

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"RTSMediaPlayer" withExtension:@"bundle"];
	if (!(self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleWithURL:bundleURL]]))
		return nil;
	
	_dataSource = dataSource;
	_identifier = identifier;
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self.mediaPlayerController setDataSource:_dataSource];
	
	[self.mediaPlayerController attachPlayerToView:self.view];
	[self.mediaPlayerController playIdentifier:_identifier];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleDefault;
}

#pragma mark - Actions

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

#pragma mark - RTSMediaPlayerControllerDataSource

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *contentURL, NSError *error))completionHandler
{
	completionHandler([NSURL URLWithString:_identifier], nil);
}

@end
