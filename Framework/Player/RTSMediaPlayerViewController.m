//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerViewController.h"

#import "NSBundle+RTSMediaPlayer.h"
#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerPlaybackButton.h"
#import "RTSPictureInPictureButton.h"
#import "RTSPlaybackActivityIndicatorView.h"
#import "RTSMediaPlayerSharedController.h"
#import "RTSMediaPlayerControllerDataSource.h"
#import "RTSTimeSlider.h"
#import "RTSVolumeView.h"

#import <libextobjc/EXTScope.h>

// Shared instance to manage picture in picture playback
static RTSMediaPlayerSharedController *s_mediaPlayerController = nil;

@interface RTSMediaPlayerViewController () <RTSMediaPlayerControllerDataSource>

@property (nonatomic, weak) id<RTSMediaPlayerControllerDataSource> dataSource;
@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, weak) IBOutlet UIView *navigationBarView;
@property (nonatomic, weak) IBOutlet UIView *bottomBarView;

@property (nonatomic, weak) IBOutlet RTSPictureInPictureButton *pictureInPictureButton;
@property (nonatomic, weak) IBOutlet RTSPlaybackActivityIndicatorView *playbackActivityIndicatorView;

@property (weak) IBOutlet RTSMediaPlayerPlaybackButton *playPauseButton;
@property (weak) IBOutlet RTSTimeSlider *timeSlider;
@property (weak) IBOutlet RTSVolumeView *volumeView;
@property (weak) IBOutlet UIButton *liveButton;

@property (weak) IBOutlet UIActivityIndicatorView *loadingActivityIndicatorView;
@property (weak) IBOutlet UILabel *loadingLabel;

@property (weak) IBOutlet NSLayoutConstraint *valueLabelWidthConstraint;
@property (weak) IBOutlet NSLayoutConstraint *timeLeftValueLabelWidthConstraint;

@end

@implementation RTSMediaPlayerViewController

+ (void)initialize
{
    if (self != [RTSMediaPlayerViewController class]) {
        return;
    }
    
    s_mediaPlayerController = [[RTSMediaPlayerSharedController alloc] init];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL
{
	return [self initWithContentIdentifier:contentURL.absoluteString dataSource:self];
}

- (instancetype)initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	if (!(self = [super initWithNibName:@"RTSMediaPlayerViewController" bundle:[NSBundle RTSMediaPlayerBundle]]))
		return nil;
	
	_dataSource = dataSource;
	_identifier = identifier;
	
	return self;
}

- (void)dealloc
{
    s_mediaPlayerController.overlayViews = nil;
    
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mediaPlayerPlaybackStateDidChange:)
												 name:RTSMediaPlayerPlaybackStateDidChangeNotification
											   object:s_mediaPlayerController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mediaPlayerDidShowControlOverlays:)
												 name:RTSMediaPlayerDidShowControlOverlaysNotification
											   object:s_mediaPlayerController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mediaPlayerDidHideControlOverlays:)
												 name:RTSMediaPlayerDidHideControlOverlaysNotification
											   object:s_mediaPlayerController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
	
	[s_mediaPlayerController setDataSource:self.dataSource];
	
	[s_mediaPlayerController attachPlayerToView:self.view];
	[s_mediaPlayerController playIdentifier:self.identifier];
    
    s_mediaPlayerController.activityView = self.view;
    s_mediaPlayerController.overlayViews = @[self.navigationBarView, self.bottomBarView, self.volumeView, self.liveButton];
    
    self.pictureInPictureButton.mediaPlayerController = s_mediaPlayerController;
    self.playbackActivityIndicatorView.mediaPlayerController = s_mediaPlayerController;
    self.timeSlider.mediaPlayerController = s_mediaPlayerController;
    self.playPauseButton.mediaPlayerController = s_mediaPlayerController;
    
	[self.liveButton setTitle:RTSMediaPlayerLocalizedString(@"Back to live", nil) forState:UIControlStateNormal];
	self.liveButton.alpha = 0.f;
    
	self.liveButton.layer.borderColor = [UIColor whiteColor].CGColor;
	self.liveButton.layer.borderWidth = 1.f;
	
	// Hide the time slider while the stream type is unknown (i.e. the needed slider label size cannot be determined)
	[self setTimeSliderHidden:YES];
	
	@weakify(self)
	[s_mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., 5.) queue:NULL usingBlock:^(CMTime time) {
		@strongify(self)
		
		if (s_mediaPlayerController.streamType != RTSMediaStreamTypeUnknown) {
			CGFloat labelWidth = (CMTimeGetSeconds(s_mediaPlayerController.timeRange.duration) >= 60. * 60.) ? 56.f : 45.f;
			self.valueLabelWidthConstraint.constant = labelWidth;
			self.timeLeftValueLabelWidthConstraint.constant = labelWidth;
			
			if (s_mediaPlayerController.playbackState != RTSMediaPlaybackStateSeeking) {
				[self updateLiveButton];
			}
			
			[self setTimeSliderHidden:NO];
		}
		else {
			[self setTimeSliderHidden:YES];
		}
	}];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (s_mediaPlayerController.pictureInPictureController.pictureInPictureActive) {
		[s_mediaPlayerController.pictureInPictureController stopPictureInPicture];
	}
}

- (void)setTimeSliderHidden:(BOOL)hidden
{
	self.timeSlider.timeLeftValueLabel.hidden = hidden;
	self.timeSlider.valueLabel.hidden = hidden;
	self.timeSlider.hidden = hidden;
	
	self.loadingActivityIndicatorView.hidden = !hidden;
	if (hidden) {
		[self.loadingActivityIndicatorView startAnimating];
	}
	else {
		[self.loadingActivityIndicatorView stopAnimating];
	}
	self.loadingLabel.hidden = !hidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleDefault;
}

#pragma mark - UI

- (void)updateLiveButton
{
	if (s_mediaPlayerController.streamType == RTSMediaStreamTypeDVR) {
		[UIView animateWithDuration:0.2 animations:^{
			self.liveButton.alpha = self.timeSlider.live ? 0.f : 1.f;
		}];
	}
	else {
		self.liveButton.alpha = 0.f;
	}
}

#pragma mark - RTSMediaPlayerControllerDataSource

- (id)mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
	  contentURLForIdentifier:(NSString *)identifier
			completionHandler:(void (^)(NSString *identifier, NSURL *contentURL, NSError *error))completionHandler
{
	completionHandler(identifier, [NSURL URLWithString:self.identifier], nil);
	
	// No need for a connection handle, completion handlers are called immediately
	return nil;
}

- (void)cancelContentURLRequest:(id)request
{}

#pragma mark - Notifications

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	if (mediaPlayerController.playbackState == RTSMediaPlaybackStateEnded) {
		[self dismiss:nil];
	}
}

- (void)mediaPlayerDidShowControlOverlays:(NSNotification *)notification
{
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)mediaPlayerDidHideControlOverlays:(NSNotification *)notificaiton
{
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    AVPictureInPictureController *pictureInPictureController = s_mediaPlayerController.pictureInPictureController;
    
    if (pictureInPictureController.isPictureInPictureActive) {
        [pictureInPictureController stopPictureInPicture];
    }
}

#pragma mark - Actions

- (IBAction)dismiss:(id)sender
{
    if (!s_mediaPlayerController.pictureInPictureController.isPictureInPictureActive) {
        [s_mediaPlayerController reset];
    }
    
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)goToLive:(id)sender
{
	[UIView animateWithDuration:0.2 animations:^{
		self.liveButton.alpha = 0.f;
	}];
	
	CMTimeRange timeRange = s_mediaPlayerController.timeRange;
	if (CMTIMERANGE_IS_INDEFINITE(timeRange) || CMTIMERANGE_IS_EMPTY(timeRange)) {
		return;
	}
	
	[s_mediaPlayerController playAtTime:CMTimeRangeGetEnd(timeRange)];
}

- (IBAction)seek:(id)sender
{
	[self updateLiveButton];
}

@end
