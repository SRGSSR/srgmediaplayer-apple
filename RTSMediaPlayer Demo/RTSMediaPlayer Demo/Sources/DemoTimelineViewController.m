//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <libextobjc/EXTScope.h>
#import "DemoTimelineViewController.h"
#import "SegmentCollectionViewCell.h"

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

- (void) setVideoIdentifier:(NSString *)videoIdentifier
{
	_videoIdentifier = videoIdentifier;
	
	[self.mediaPlayerController playIdentifier:videoIdentifier];
}

#pragma mark - View lifecycle

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	NSString *className = NSStringFromClass([SegmentCollectionViewCell class]);
	UINib *cellNib = [UINib nibWithNibName:className bundle:nil];
	[self.timelineView registerNib:cellNib forCellWithReuseIdentifier:className];
	
	[self.mediaPlayerController attachPlayerToView:self.videoView];
	
	@weakify(self)
	[self.mediaPlayerController addPlaybackTimeObserverForInterval:CMTimeMakeWithSeconds(30., 1.) queue:NULL usingBlock:^(CMTime time) {
		@strongify(self)
		[self.timelineView reloadSegmentsForIdentifier:self.videoIdentifier];
		[self.timelineSlider reloadSegmentsForIdentifier:self.videoIdentifier];
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

- (UIImage *) timelineSlider:(RTSTimelineSlider *)timelineSlider iconImageForSegment:(id<RTSMediaPlayerSegment>)segment
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

- (void) timelineView:(RTSTimelineView *)timelineView didSelectSegment:(id<RTSMediaPlayerSegment>)segment
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
