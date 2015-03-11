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

@property (weak) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak) IBOutlet RTSPlayPauseButton *playPauseButton;
@property (weak) IBOutlet RTSTimeSlider *timeSlider;
@property (weak) IBOutlet RTSVolumeView *volumeView;

@end



@implementation RTSMediaPlayerViewController

- (instancetype) initWithContentURL:(NSURL *)contentURL
{
	return [self initWithContentIdentifier:contentURL.absoluteString dataSource:self];
}

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	NSURL *mediaPlayerBundleURL = [[NSBundle mainBundle] URLForResource:@"RTSMediaPlayer" withExtension:@"bundle"];
	NSAssert(mediaPlayerBundleURL != nil, @"RTSMediaPlayer.bundle not found in the main bundle's resources");
	if (!(self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleWithURL:mediaPlayerBundleURL]]))
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackDidFinishNotification:) name:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackStateDidChangeNotification:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
	return UIStatusBarStyleDefault;
}



#pragma mark - RTSMediaPlayerControllerDataSource

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *contentURL, NSError *error))completionHandler
{
	completionHandler([NSURL URLWithString:_identifier], nil);
}



#pragma mark - Notifications

- (void) mediaPlayerPlaybackDidFinishNotification:(NSNotification *)notification
{
	RTSMediaFinishReason reason = [notification.userInfo[RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
	if (reason == RTSMediaFinishReasonPlaybackEnded)
		[self dismiss:nil];
}

- (void) mediaPlayerPlaybackStateDidChangeNotification:(NSNotification *)notification
{
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	if (mediaPlayerController.playbackState == RTSMediaPlaybackStatePendingPlay)
		[self.loadingIndicator startAnimating];
	else
		[self.loadingIndicator stopAnimating];
}



#pragma mark - Actions

- (IBAction) dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}



@end
