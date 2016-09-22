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
@property (nonatomic, weak) Segment *selectedSegment;

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

    self.timelineSlider.delegate = self;
    self.blockingOverlayView.hidden = YES;

    NSString *className = NSStringFromClass([SegmentCollectionViewCell class]);
    UINib *cellNib = [UINib nibWithNibName:className bundle:nil];
    [self.timelineView registerNib:cellNib forCellWithReuseIdentifier:className];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSkipSegment:)
                                                 name:SRGMediaPlayerDidSkipBlockedSegmentNotification
                                               object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(segmentDidStart:)
                                                 name:SRGMediaPlayerSegmentDidStartNotification
                                               object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(segmentDidEnd:)
                                                 name:SRGMediaPlayerSegmentDidEndNotification
                                               object:self.mediaPlayerController];
}

- (void)updateAppearanceWithTime:(CMTime)time
{
    if (self.selectedSegment) {
        time = self.selectedSegment.srg_timeRange.start;
    }
    
    for (SegmentCollectionViewCell *segmentCell in [self.timelineView visibleCells]) {
        [segmentCell updateAppearanceWithTime:time selectedSegment:self.selectedSegment];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        [self.mediaPlayerController playURL:self.contentURL atTime:kCMTimeZero withSegments:self.segments userInfo:nil];
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
            return CMTimeRangeContainsTime(segment.srg_timeRange, time);
        }];
        
        id<SRGSegment> segment = [self.timelineView.mediaPlayerController.segments filteredArrayUsingPredicate:predicate].firstObject;
        if (segment) {
            [self.timelineView scrollToSegment:segment animated:YES];
        }
        
        self.selectedSegment = nil;
    }
}

#pragma mark SRGTimelineViewDelegate protocol

- (UICollectionViewCell *)timelineView:(SRGTimelineView *)timelineView cellForSegment:(id<SRGSegment>)segment
{
    SegmentCollectionViewCell *segmentCell = [timelineView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SegmentCollectionViewCell class]) forSegment:segment];
    segmentCell.segment = (Segment *)segment;
    return segmentCell;
}

- (void)timelineView:(SRGTimelineView *)timelineView didSelectSegmentAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedSegment = self.segments[indexPath.row];
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

- (void)segmentDidStart:(NSNotification *)notification
{
    NSLog(@"Segment did start: %@", notification.userInfo);
    
    Segment *segment = notification.userInfo[SRGMediaPlayerSegmentKey];
    if (segment == self.selectedSegment) {
        self.selectedSegment = nil;
    }
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    NSLog(@"Segment did end: %@", notification.userInfo);
}

@end
