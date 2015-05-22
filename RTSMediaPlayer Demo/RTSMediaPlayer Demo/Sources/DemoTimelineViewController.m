//
//  Created by Samuel Défago on 29.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "DemoTimelineViewController.h"

#import "EventCollectionViewCell.h"

@interface DemoTimelineViewController ()

@property (nonatomic) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet RTSTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet RTSTimelineSlider *timelineSlider;

@end

@implementation DemoTimelineViewController

#pragma mark - Object lifecycle

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getters and setters

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	if (_mediaPlayerController)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:RTSMediaPlayerPlaybackDidFailNotification
													  object:_mediaPlayerController];
	}
	
	_mediaPlayerController = mediaPlayerController;
	
	if (mediaPlayerController)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playbackDidFail:)
													 name:RTSMediaPlayerPlaybackDidFailNotification
												   object:mediaPlayerController];
	}
}

- (void) setVideoIdentifier:(NSString *)videoIdentifier
{
	_videoIdentifier = videoIdentifier;
	
	[self.mediaPlayerController playIdentifier:videoIdentifier];
}

#pragma mark - View lifecycle

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.timelineView.itemWidth = 162.f;
	self.timelineView.itemSpacing = 0.f;
	
	NSString *className = NSStringFromClass([EventCollectionViewCell class]);
	UINib *cellNib = [UINib nibWithNibName:className bundle:nil];
	[self.timelineView registerNib:cellNib forCellWithReuseIdentifier:className];
	
	[self.mediaPlayerController attachPlayerToView:self.videoView];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if ([self isMovingToParentViewController] || [self isBeingPresented])
	{
		[self.mediaPlayerController playIdentifier:self.videoIdentifier];
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
	}
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if ([self isMovingFromParentViewController] || [self isBeingDismissed])
	{
		[self.mediaPlayerController reset];
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
	}
}

#pragma mark - RTSTimelineViewDelegate protocol

- (UICollectionViewCell *) timelineView:(RTSTimelineView *)timelineView cellForSegment:(RTSMediaPlayerSegment *)segment
{
	EventCollectionViewCell *eventCell = [timelineView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([EventCollectionViewCell class]) forSegment:segment];
	eventCell.event = (Event *)segment;
	return eventCell;
}

#pragma mark - Actions

- (IBAction) dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) seekBackward:(id)sender
{
	CMTime currentTime = self.mediaPlayerController.player.currentTime;
	CMTime increment = CMTimeMakeWithSeconds(30., 1.);
	
	[self.mediaPlayerController.player seekToTime:CMTimeSubtract(currentTime, increment)];
}

- (IBAction) seekForward:(id)sender
{
	CMTime currentTime = self.mediaPlayerController.player.currentTime;
	CMTime increment = CMTimeMakeWithSeconds(30., 1.);
	
	[self.mediaPlayerController.player seekToTime:CMTimeAdd(currentTime, increment)];
}

- (IBAction) goToLive:(id)sender
{
	[self.mediaPlayerController.player seekToTime:self.mediaPlayerController.player.currentItem.duration];
}

#pragma mark - Notifications

- (void) playbackDidFail:(NSNotification *)notifications
{
	[self dismissViewControllerAnimated:YES completion:nil];
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
														message:@"The video could not be played"
													   delegate:nil
											  cancelButtonTitle:@"Dismiss"
											  otherButtonTitles:nil];
	[alertView show];
}

@end
