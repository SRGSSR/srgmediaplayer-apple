//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <libextobjc/EXTScope.h>
#import "DemoTimelineViewController.h"
#import "SwissTXTSegmentCollectionViewCell.h"

@interface DemoTimelineViewController ()

@property (nonatomic) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet RTSSegmentedTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet RTSTimelineSlider *timelineSlider;

@end

@implementation DemoTimelineViewController

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

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.mediaPlayerController.overlayViewsHidingDelay = 1000;
	
	NSString *className = NSStringFromClass([SwissTXTSegmentCollectionViewCell class]);
	UINib *cellNib = [UINib nibWithNibName:className bundle:nil];
	[self.timelineView registerNib:cellNib forCellWithReuseIdentifier:className];
	
	[self.mediaPlayerController attachPlayerToView:self.videoView];
	
	@weakify(self)
	[self.mediaPlayerController addPlaybackTimeObserverForInterval:CMTimeMakeWithSeconds(30., 1.) queue:NULL usingBlock:^(CMTime time) {
		@strongify(self)
		[self.timelineView reloadSegmentsForIdentifier:self.videoIdentifier completionHandler:nil];
		[self.timelineSlider reloadSegmentsForIdentifier:self.videoIdentifier completionHandler:nil];
	}];
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

#pragma ark - RTSTimelineSliderDelegate protocol

- (UIImage *) timelineSlider:(RTSTimelineSlider *)timelineSlider iconImageForSegment:(id<RTSMediaSegment>)segment
{
	return ((SwissTXTSegment *)segment).iconImage;
}

#pragma mark - RTSSegmentedTimelineViewDelegate protocol

- (UICollectionViewCell *) timelineView:(RTSSegmentedTimelineView *)timelineView cellForSegment:(id<RTSMediaSegment>)segment
{
	SwissTXTSegmentCollectionViewCell *segmentCell = [timelineView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SwissTXTSegmentCollectionViewCell class]) forSegment:segment];
	segmentCell.segment = (SwissTXTSegment *)segment;
	return segmentCell;
}

- (void) timelineView:(RTSSegmentedTimelineView *)timelineView didSelectSegment:(id<RTSMediaSegment>)segment
{
	[self.mediaPlayerController seekToTime:segment.timeRange.start completionHandler:nil];
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
