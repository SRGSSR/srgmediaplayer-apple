//
//  DemoSegmentsBlockingViewController.m
//  RTSMediaPlayer Demo
//
//  Created by Cédric Foellmi on 01/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <libextobjc/EXTScope.h>
#import "DemoSegmentsBlockingViewController.h"
#import "PseudoILDataProvider.h"
#import "SegmentCollectionViewCell.h"

@interface DemoSegmentsBlockingViewController ()

@property (nonatomic) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet RTSTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet RTSTimelineSlider *timelineSlider;

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

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.timelineView.itemWidth = 162.f;
	self.timelineView.itemSpacing = 0.f;
	
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
	[self.mediaPlayerController.player seekToTime:segment.segmentTimeRange.start];
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


@end
