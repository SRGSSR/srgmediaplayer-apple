//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>

#import "VideoTimeshiftPlayerViewController.h"
#import "PseudoILDataProvider.h"
#import "SegmentCollectionViewCell.h"

static NSString *StringForPlaybackState(RTSPlaybackState playbackState)
{
	static dispatch_once_t s_onceToken;
	static NSDictionary *s_names;
	dispatch_once(&s_onceToken, ^{
		s_names = @{ @(RTSPlaybackStateIdle) : @"IDLE",
					 @(RTSPlaybackStatePreparing) : @"PREPARING",
					 @(RTSPlaybackStateReady) : @"READY",
					 @(RTSPlaybackStatePlaying) : @"PLAYING",
					 @(RTSPlaybackStateSeeking) : @"SEEKING",
					 @(RTSPlaybackStatePaused) : @"PAUSED",
					 @(RTSPlaybackStateStalled) : @"STALLED",
					 @(RTSPlaybackStateEnded) : @"ENDED",};
	});
	return s_names[@(playbackState)] ?: @"UNKNOWN";
}

@interface VideoTimeshiftPlayerViewController ()

@property (nonatomic) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet RTSTimeSlider *timelineSlider;
@property (nonatomic, weak) IBOutlet UIButton *liveButton;

@property (nonatomic, weak) IBOutlet UIView *blockingOverlayView;
@property (nonatomic, weak) IBOutlet UILabel *blockingOverlayViewLabel;

@property (nonatomic, weak) NSTimer *blockingOverlayTimer;
@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation VideoTimeshiftPlayerViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.mediaPlayerController.overlayViewsHidingDelay = 1000;
	self.blockingOverlayView.hidden = YES;
	[self.mediaPlayerController attachPlayerToView:self.videoView];
	
	[self.liveButton setTitle:@"Back to live" forState:UIControlStateNormal];
	self.liveButton.alpha = 0.f;
	
	self.liveButton.layer.borderColor = [UIColor whiteColor].CGColor;
	self.liveButton.layer.borderWidth = 1.f;

	__weak __typeof(self) weakSelf = self;
	[self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., 5.) queue:NULL usingBlock:^(CMTime time) {
		if (weakSelf.mediaPlayerController.playbackState != RTSPlaybackStateSeeking) {
			[weakSelf updateLiveButton];
		}
	}];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(playbackStateDidChange:)
												 name:RTSMediaPlayerPlaybackStateDidChangeNotification
											   object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if ([self isMovingToParentViewController] || [self isBeingPresented]) {
		[self.mediaPlayerController play];
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
		[self.mediaPlayerController reset];
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
	}
}

- (void)updateLiveButton
{
	if (self.mediaPlayerController.streamType == RTSMediaStreamTypeDVR) {
		[UIView animateWithDuration:0.2 animations:^{
			self.liveButton.alpha = self.timelineSlider.live ? 0.f : 1.f;
		}];
	}
	else {
		self.liveButton.alpha = 0.f;
	}	
}

#pragma mark - RTSMediaPlayerControllerDataSource

- (void)mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
	  contentURLForIdentifier:(NSString *)identifier
			completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	if (self.tokenizeMediaURL) {
		NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
		
		NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL:self.mediaURL
													   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
														   if (error) {
															   completionHandler(nil, error);
														   }
														   else {
															   NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
															   if ([text hasPrefix:@"\""]) {
																   text = [text substringFromIndex:1];
															   }
															   if ([text hasSuffix:@"\""]) {
																   text = [text substringToIndex:text.length-1];
															   }
															   NSParameterAssert([NSURL URLWithString:text]);
															   completionHandler([NSURL URLWithString:text], nil);
															}
														}];
		
		[dataTask resume];
	}
	else {
		completionHandler(self.mediaURL, nil);
	}
}

#pragma mark - Notifications

- (void)playbackStateDidChange:(NSNotification *)notification
{
	NSLog(@"Playback state [%@]", StringForPlaybackState(self.mediaPlayerController.playbackState));
}

#pragma mark - Actions

- (IBAction)dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)goToLive:(id)sender
{
	[UIView animateWithDuration:0.2 animations:^{
		self.liveButton.alpha = 0.f;
	}];
	
	CMTimeRange timeRange = self.mediaPlayerController.timeRange;
	if (CMTIMERANGE_IS_INDEFINITE(timeRange) || CMTIMERANGE_IS_EMPTY(timeRange)) {
		return;
	}
	
	[self.mediaPlayerController playAtTime:CMTimeRangeGetEnd(timeRange)];
}

- (IBAction)seek:(id)sender
{
	[self updateLiveButton];
}

@end
