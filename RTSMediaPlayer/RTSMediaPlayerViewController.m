//
//  Created by Frédéric Humbert-Droz on 03/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerViewController.h"

#import <RTSMediaPlayer/NSBundle+RTSMediaPlayer.h>
#import <RTSMediaPlayer/RTSMediaPlayerControllerDataSource.h>
#import <RTSMediaPlayer/RTSMediaPlayerController.h>

@interface RTSMediaPlayerViewController () <RTSMediaPlayerControllerDataSource>

@property (nonatomic, weak) id<RTSMediaPlayerControllerDataSource> dataSource;
@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, strong) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (weak) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak) IBOutlet RTSMediaPlayerPlaybackButton *playPauseButton;
@property (weak) IBOutlet RTSTimeSlider *timeSlider;
@property (weak) IBOutlet RTSVolumeView *volumeView;

@end

@implementation RTSMediaPlayerViewController

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (instancetype) initWithContentURL:(NSURL *)contentURL
{
	return [self initWithContentIdentifier:contentURL.absoluteString dataSource:self];
}

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	if (!(self = [super initWithNibName:@"RTSMediaPlayerViewController" bundle:[NSBundle RTSMediaPlayerBundle]]))
		return nil;
	
	_dataSource = dataSource;
	_identifier = identifier;
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackStateDidChange:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerDidShowControlOverlays:) name:RTSMediaPlayerDidShowControlOverlaysNotification object:self.mediaPlayerController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerDidHideControlOverlays:) name:RTSMediaPlayerDidHideControlOverlaysNotification object:self.mediaPlayerController];
	
	[self.mediaPlayerController setDataSource:self.dataSource];
	
	[self.mediaPlayerController attachPlayerToView:self.view];
	[self.mediaPlayerController playIdentifier:self.identifier];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
	return UIStatusBarStyleDefault;
}



#pragma mark - RTSMediaPlayerControllerDataSource

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *contentURL, NSError *error))completionHandler
{
	completionHandler([NSURL URLWithString:self.identifier], nil);
}



#pragma mark - Notifications

- (void) mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	switch (mediaPlayerController.playbackState)
	{
		case RTSMediaPlaybackStatePreparing:
		case RTSMediaPlaybackStateReady:
		case RTSMediaPlaybackStateStalled:
			[self.loadingIndicator startAnimating];
			break;
		case RTSMediaPlaybackStateEnded:
			[self dismiss:nil];
		case RTSMediaPlaybackStatePaused:
		case RTSMediaPlaybackStatePlaying:
		default:
			[self.loadingIndicator stopAnimating];
			break;
	}
}

- (void) mediaPlayerDidShowControlOverlays:(NSNotification *)notification
{
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void) mediaPlayerDidHideControlOverlays:(NSNotification *)notificaiton
{
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
}



#pragma mark - Actions

- (IBAction) dismiss:(id)sender
{
	[self.mediaPlayerController reset];
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
