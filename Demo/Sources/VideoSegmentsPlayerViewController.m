//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "VideoSegmentsPlayerViewController.h"

#import "SegmentCollectionViewCell.h"

@interface VideoSegmentsPlayerViewController ()

@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;         // top object, strong

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet SRGTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet SRGTimeSlider *timelineSlider;

@property (nonatomic, weak) IBOutlet UIView *blockingOverlayView;
@property (nonatomic, weak) IBOutlet UILabel *blockingOverlayViewLabel;

@property (nonatomic, weak) NSTimer *blockingOverlayTimer;
@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation VideoSegmentsPlayerViewController

#pragma mark Object lifecycle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.timelineSlider.slidingDelegate = self;
    self.blockingOverlayView.hidden = YES;

    NSString *className = NSStringFromClass([SegmentCollectionViewCell class]);
    UINib *cellNib = [UINib nibWithNibName:className bundle:nil];
    [self.timelineView registerNib:cellNib forCellWithReuseIdentifier:className];
    
    self.mediaPlayerController.view.frame = self.view.bounds;
    self.mediaPlayerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:self.mediaPlayerController.view atIndex:0];
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
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
        
        // FIXME: Play, load segments, handle blocked segments
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

#pragma ark SRGTimeSliderDelegate protocol

- (void)timeSlider:(SRGTimeSlider *)slider isMovingToPlaybackTime:(CMTime)time withValue:(CGFloat)value interactive:(BOOL)interactive
{
    [self updateAppearanceWithTime:time];

    if (interactive) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id<SRGSegment> _Nonnull segment, NSDictionary<NSString *, id> *_Nullable bindings) {
            return CMTimeRangeContainsTime(segment.timeRange, time);
        }];
        
        id<SRGSegment> segment = [self.timelineView.mediaPlayerController.segments filteredArrayUsingPredicate:predicate].firstObject;
        if (segment) {
            [self.timelineView scrollToSegment:segment animated:YES];
        }
    }
}

#pragma mark SRGTimelineViewDelegate protocol

- (UICollectionViewCell *)timelineView:(SRGTimelineView *)timelineView cellForSegment:(id<SRGSegment>)segment
{
    SegmentCollectionViewCell *segmentCell = [timelineView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SegmentCollectionViewCell class]) forSegment:segment];
    segmentCell.segment = (Segment *)segment;
    return segmentCell;
}

- (void)timelineViewDidScroll:(SRGTimelineView *)timelineView
{
    [self updateAppearanceWithTime:self.timelineSlider.time];
}

#pragma mark - Actions

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)seekBackward:(id)sender
{
    CMTime currentTime = self.mediaPlayerController.player.currentTime;
    CMTime increment = CMTimeMakeWithSeconds(30., 1.);
    [self.mediaPlayerController seekToTime:CMTimeSubtract(currentTime, increment) withCompletionHandler:nil];
}

- (IBAction)seekForward:(id)sender
{
    CMTime currentTime = self.mediaPlayerController.player.currentTime;
    CMTime increment = CMTimeMakeWithSeconds(30., 1.);
    [self.mediaPlayerController seekToTime:CMTimeAdd(currentTime, increment) withCompletionHandler:nil];
}

- (IBAction)goToLive:(id)sender
{
    [self.mediaPlayerController seekToTime:self.mediaPlayerController.player.currentItem.duration withCompletionHandler:nil];
}

@end
