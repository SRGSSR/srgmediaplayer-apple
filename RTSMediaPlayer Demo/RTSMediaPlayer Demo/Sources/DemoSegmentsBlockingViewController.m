//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <libextobjc/EXTScope.h>
#import "DemoSegmentsBlockingViewController.h"
#import "PseudoILDataProvider.h"
#import "SegmentCollectionViewCell.h"

@interface DemoSegmentsBlockingViewController ()

@property (nonatomic) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet RTSTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet RTSTimeSlider *timelineSlider;
@property (nonatomic, weak) IBOutlet UIView *blockingOverlayView;
@property (nonatomic, weak) IBOutlet UILabel *blockingOverlayViewLabel;
@property (nonatomic, weak) NSTimer *blockingOverlayTimer;

@end

@implementation DemoSegmentsBlockingViewController

#pragma mark - Object lifecycle

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getters and setters

- (void) setVideoIdentifier:(NSString *)videoIdentifier
{
	_videoIdentifier = videoIdentifier;
	[self.mediaPlayerController playIdentifier:videoIdentifier];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.mediaPlayerController.overlayViewsHidingDelay = 1000;
	
	NSString *className = NSStringFromClass([SegmentCollectionViewCell class]);
	UINib *cellNib = [UINib nibWithNibName:className bundle:nil];
	[self.timelineView registerNib:cellNib forCellWithReuseIdentifier:className];
	
	[self.mediaPlayerController attachPlayerToView:self.videoView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(displayBlockingMessage:)
												 name:RTSMediaPlaybackSegmentDidChangeNotification
											   object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if ([self isMovingToParentViewController] || [self isBeingPresented]) {
		[self.mediaPlayerController playIdentifier:self.videoIdentifier];
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
		[self.timelineView reloadSegmentsForIdentifier:self.videoIdentifier];
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

- (void)displayBlockingMessage:(NSNotification *)notification
{
	RTSMediaSegmentsController *sender = (RTSMediaSegmentsController *)notification.object;
	if (sender.playerController != self.mediaPlayerController) {
		return;
	}
	
	NSNumber *value = notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey];
	if (value && [value integerValue] == RTSMediaPlaybackSegmentSeekUponBlocking) {
		self.blockingOverlayViewLabel.text = @"Blocked Segment. Seeking to next authorized one... \nMessage shown during 5 seconds (customizable).";
		[self.blockingOverlayView setHidden:NO];
		
		self.blockingOverlayTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
																	 target:self
																   selector:@selector(considerHidingTheBlockingMessage:)
																   userInfo:nil
																	repeats:NO];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(considerHidingTheBlockingMessage:)
													 name:RTSMediaPlayerPlaybackStateDidChangeNotification
												   object:self.mediaPlayerController];
	}
}

- (void)considerHidingTheBlockingMessage:(id)sender
{
	if (self.blockingOverlayView.isHidden) {
		// The overlay view is already hidden.
		return;
	}
	
	if ([sender isKindOfClass:[NSNotification class]] && self.blockingOverlayTimer) {
		// Okay, wait for the timer to trigger the hide.
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:RTSMediaPlayerPlaybackStateDidChangeNotification
													  object:self.mediaPlayerController];
		
		return;
	}
	
	[self.blockingOverlayView setHidden:YES];
}

#pragma ark - RTSTimelineSliderDelegate protocol

- (UIImage *)timelineSlider:(RTSTimelineSlider *)timelineSlider iconImageForSegment:(id<RTSMediaPlayerSegment>)segment
{
	return ((Segment *)segment).iconImage;
}

#pragma mark - RTSTimelineViewDelegate protocol

- (UICollectionViewCell *) timelineView:(RTSTimelineView *)timelineView cellForSegment:(id<RTSMediaPlayerSegment>)segment
{
	SegmentCollectionViewCell *segmentCell = [timelineView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SegmentCollectionViewCell class]) forSegment:segment];
	segmentCell.segment = (Segment *)segment;
	return segmentCell;
}

- (void)timelineView:(RTSTimelineView *)timelineView didSelectSegment:(id<RTSMediaPlayerSegment>)segment
{
	[self.mediaPlayerController seekToTime:segment.segmentTimeRange.start completionHandler:nil];
}

#pragma mark - Actions

- (IBAction)dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)seekBackward:(id)sender
{
	CMTime currentTime = self.mediaPlayerController.playerItem.currentTime;
	CMTime increment = CMTimeMakeWithSeconds(30., 1.);
	[self.mediaPlayerController seekToTime:CMTimeSubtract(currentTime, increment) completionHandler:nil];
}

- (IBAction)seekForward:(id)sender
{
	CMTime currentTime = self.mediaPlayerController.playerItem.currentTime;
	CMTime increment = CMTimeMakeWithSeconds(30., 1.);
	[self.mediaPlayerController seekToTime:CMTimeAdd(currentTime, increment) completionHandler:nil];
}

- (IBAction)goToLive:(id)sender
{
	[self.mediaPlayerController seekToTime:self.mediaPlayerController.playerItem.duration completionHandler:nil];
}


@end
