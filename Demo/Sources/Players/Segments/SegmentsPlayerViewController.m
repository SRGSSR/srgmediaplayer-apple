//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SegmentsPlayerViewController.h"

#import "SegmentCollectionViewCell.h"

@interface SegmentsPlayerViewController ()

@property (nonatomic) NSURL *contentURL;
@property (nonatomic) NSArray<Segment *> *segments;

@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;         // top object, strong

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet SRGTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet SRGTimeSlider *timelineSlider;

@property (nonatomic, weak) IBOutlet UIView *blockingOverlayView;

@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation SegmentsPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithContentURL:(NSURL *)contentURL segments:(NSArray<Segment *> *)segments
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    SegmentsPlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.contentURL = contentURL;
    viewController.segments = segments;
    return viewController;
}

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSkipSegment:)
                                                 name:SRGMediaPlayerDidSkipBlockedSegmentNotification
                                               object:self.mediaPlayerController];
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
        [self.mediaPlayerController playURL:self.contentURL withSegments:self.segments];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        [self.mediaPlayerController reset];
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

#pragma mark Actions

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)seekBackward:(id)sender
{
    CMTime currentTime = self.mediaPlayerController.player.currentTime;
    CMTime increment = CMTimeMakeWithSeconds(30., NSEC_PER_SEC);
    [self.mediaPlayerController seekToTime:CMTimeSubtract(currentTime, increment) withCompletionHandler:nil];
}

- (IBAction)seekForward:(id)sender
{
    CMTime currentTime = self.mediaPlayerController.player.currentTime;
    CMTime increment = CMTimeMakeWithSeconds(30., NSEC_PER_SEC);
    [self.mediaPlayerController seekToTime:CMTimeAdd(currentTime, increment) withCompletionHandler:nil];
}

- (IBAction)goToLive:(id)sender
{
    [self.mediaPlayerController seekToTime:self.mediaPlayerController.player.currentItem.duration withCompletionHandler:nil];
}

#pragma mark Notifications

- (void)didSkipSegment:(NSNotification *)notification
{
    self.blockingOverlayView.hidden = NO;
    [self.mediaPlayerController pause];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.blockingOverlayView.hidden = YES;
        [self.mediaPlayerController play];
    });
}

@end
