//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <libextobjc/EXTScope.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

#import "VideoSegmentsPlayerViewController.h"
#import "PseudoILDataProvider.h"
#import "SegmentCollectionViewCell.h"

static NSString *StringForSegmentChange(RTSMediaPlaybackSegmentChange segmentChange)
{
	static dispatch_once_t s_onceToken;
	static NSDictionary *s_names;
	dispatch_once(&s_onceToken, ^{
		s_names = @{ @(RTSMediaPlaybackSegmentStart) : @"START",
					 @(RTSMediaPlaybackSegmentEnd) : @"END",
					 @(RTSMediaPlaybackSegmentSwitch) : @"SWITCH",
					 @(RTSMediaPlaybackSegmentSeekUponBlockingStart) : @"SEEK START",
					 @(RTSMediaPlaybackSegmentSeekUponBlockingEnd) : @"SEEK END" };
	});
	return s_names[@(segmentChange)] ?: @"UNKNOWN";
}

static NSString *StringForPlaybackState(RTSMediaPlaybackState playbackState)
{
	static dispatch_once_t s_onceToken;
	static NSDictionary *s_names;
	dispatch_once(&s_onceToken, ^{
		s_names = @{ @(RTSMediaPlaybackStateIdle) : @"IDLE",
					 @(RTSMediaPlaybackStatePreparing) : @"PREPARING",
					 @(RTSMediaPlaybackStateReady) : @"READY",
					 @(RTSMediaPlaybackStatePlaying) : @"PLAYING",
					 @(RTSMediaPlaybackStateSeeking) : @"SEEKING",
					 @(RTSMediaPlaybackStatePaused) : @"PAUSED",
					 @(RTSMediaPlaybackStateStalled) : @"STALLED",
					 @(RTSMediaPlaybackStateEnded) : @"ENDED",};
	});
	return s_names[@(playbackState)] ?: @"UNKNOWN";
}

@interface VideoSegmentsPlayerViewController () <RTSTimeSliderDelegate>

@property (nonatomic) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet RTSSegmentedTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet RTSTimeSlider *timelineSlider;

@property (nonatomic, weak) IBOutlet UIView *blockingOverlayView;
@property (nonatomic, weak) IBOutlet UILabel *blockingOverlayViewLabel;

@property (nonatomic, weak) NSTimer *blockingOverlayTimer;
@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation VideoSegmentsPlayerViewController

#pragma mark - Object lifecycle

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getters and setters

- (void)setVideoIdentifier:(NSString *)videoIdentifier
{
	_videoIdentifier = videoIdentifier;
	[self.mediaPlayerController playIdentifier:videoIdentifier];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.timelineSlider.slidingDelegate = self;
	self.mediaPlayerController.overlayViewsHidingDelay = 1000;
	self.blockingOverlayView.hidden = YES;
	
	NSString *className = NSStringFromClass([SegmentCollectionViewCell class]);
	UINib *cellNib = [UINib nibWithNibName:className bundle:nil];
	[self.timelineView registerNib:cellNib forCellWithReuseIdentifier:className];
	
	[self.mediaPlayerController attachPlayerToView:self.videoView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(considerDisplayBlockingMessage:)
												 name:RTSMediaPlaybackSegmentDidChangeNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(segmentDidChange:)
												 name:RTSMediaPlaybackSegmentDidChangeNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(playbackStateDidChange:)
												 name:RTSMediaPlayerPlaybackStateDidChangeNotification
											   object:nil];
}

- (void)updateAppearanceWithTime:(CMTime)time
{
	for (SegmentCollectionViewCell *segmentCell in [self.timelineView visibleCells]) {
		[segmentCell updateAppearanceWithTime:time];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if ([self isMovingToParentViewController] || [self isBeingPresented]) {
		[self.mediaPlayerController playIdentifier:self.videoIdentifier];
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
		[self.timelineView reloadSegmentsForIdentifier:self.videoIdentifier completionHandler:nil];
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

#pragma mark - Notifications

/**
 *  Example of handling a kind of race condition where we want the playback to restart as soon as it is ready,
 *  but not before the time of displaying the message is over.
 */
- (void)considerDisplayBlockingMessage:(NSNotification *)notification
{
	RTSMediaSegmentsController *sender = (RTSMediaSegmentsController *)notification.object;
	if (sender.playerController != self.mediaPlayerController) {
		return;
	}
	
	NSNumber *value = notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey];
	if (!value) {
		return;
	}
	
	if ([value integerValue] == RTSMediaPlaybackSegmentSeekUponBlockingStart) {
		NSTimeInterval blockingMessageDuration = 10.0;

		self.blockingOverlayViewLabel.text = [NSString stringWithFormat:
											  @"Blocked Segment. Seeking to next authorized one... \nMessage shown during %.0f seconds (customizable).",
											  blockingMessageDuration];
		
		[self.blockingOverlayView setHidden:NO];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, blockingMessageDuration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self.blockingOverlayView setHidden:YES];
			if (self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused) {
				[self.mediaPlayerController play];
			}
		});
	}
	else if ([value integerValue] == RTSMediaPlaybackSegmentSeekUponBlockingEnd) {
		if (self.blockingOverlayView.isHidden) {
			[self.mediaPlayerController play];
		}
	}
}

- (void)segmentDidChange:(NSNotification *)notification
{
	RTSMediaPlaybackSegmentChange segmentChange = [notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue];
	Segment *previousSegment = notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey];
	Segment *segment = notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey];
	BOOL wasSelected = [notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue];
	
	NSLog(@"Segment [%@]: previous = %@, current = %@, user selected: %@", StringForSegmentChange(segmentChange), previousSegment.title, segment.title, wasSelected ? @"YES" : @"NO");
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
	NSLog(@"Playback state [%@]", StringForPlaybackState(self.mediaPlayerController.playbackState));
}

#pragma ark - RTSTimeSliderDelegate protocol

- (void)timeSlider:(RTSTimeSlider *)slider isSlidingAtPlaybackTime:(CMTime)time withValue:(CGFloat)value
{
	[self updateAppearanceWithTime:time];
	
	NSUInteger visibleSegmentIndex = [self.timelineView.segmentsController indexOfVisibleSegmentForTime:time];
	if (visibleSegmentIndex != NSNotFound) {
		id<RTSMediaSegment> segment = [[self.timelineView.segmentsController visibleSegments] objectAtIndex:visibleSegmentIndex];
		[self.timelineView scrollToSegment:segment animated:YES];
	}
}

#pragma mark - RTSSegmentedTimelineViewDelegate protocol

- (UICollectionViewCell *)timelineView:(RTSSegmentedTimelineView *)timelineView cellForSegment:(id<RTSMediaSegment>)segment
{
	SegmentCollectionViewCell *segmentCell = [timelineView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SegmentCollectionViewCell class]) forSegment:segment];
	segmentCell.segment = (Segment *)segment;
	return segmentCell;
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
