//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "RTSMediaPlayerViewController.h"

#import "NSBundle+RTSMediaPlayer.h"
#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerPlaybackButton.h"
#import "RTSTimeSlider.h"
#import "RTSVolumeView.h"

#import <libextobjc/EXTScope.h>

@interface RTSMediaPlayerViewController () <RTSMediaPlayerControllerDataSource>

@property (nonatomic, weak) id<RTSMediaPlayerControllerDataSource> dataSource;
@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, strong) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (weak) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak) IBOutlet RTSMediaPlayerPlaybackButton *playPauseButton;
@property (weak) IBOutlet RTSTimeSlider *timeSlider;
@property (weak) IBOutlet RTSVolumeView *volumeView;

@property (weak) IBOutlet NSLayoutConstraint *valueLabelWidthConstraint;
@property (weak) IBOutlet NSLayoutConstraint *timeLeftValueLabelWidthConstraint;

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
	
	@weakify(self)
	[self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., 5.) queue:NULL usingBlock:^(CMTime time) {
		@strongify(self)
		
		CGFloat labelWidth = (CMTimeGetSeconds(self.mediaPlayerController.timeRange.duration) >= 60. * 60.) ? 56.f : 45.f;
		self.valueLabelWidthConstraint.constant = labelWidth;
		self.timeLeftValueLabelWidthConstraint.constant = labelWidth;
	}];
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

- (IBAction) goToLive:(id)sender
{
	CMTimeRange timeRange = self.mediaPlayerController.timeRange;
	if (CMTIMERANGE_IS_INDEFINITE(timeRange) || CMTIMERANGE_IS_EMPTY(timeRange)) {
		return;
	}
	
	[self.mediaPlayerController playAtTime:CMTimeRangeGetEnd(timeRange)];
}

@end
