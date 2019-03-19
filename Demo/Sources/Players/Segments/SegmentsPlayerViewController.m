//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SegmentsPlayerViewController.h"

#import "ModalTransition.h"
#import "SegmentCollectionViewCell.h"

@interface SegmentsPlayerViewController ()

@property (nonatomic) Media *media;

@property (nonatomic, weak) DemoSegment *selectedSegment;

@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;         // top object, strong

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet SRGTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet SRGTimeSlider *timelineSlider;

@property (nonatomic, weak) IBOutlet UIView *blockingOverlayView;

@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic, weak) IBOutlet UISwitch *externalPlaybackSwitch;

@property (nonatomic) ModalTransition *interactiveTransition;

@end

@implementation SegmentsPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithMedia:(Media *)media
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    SegmentsPlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.media = media;
    return viewController;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Use a custom transition, some subtle issues were discovered with incorrect implementations, when animated
    // view controllers have an AVPlayer somewhere.
    self.transitioningDelegate = self;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.timelineSlider.delegate = self;
    self.blockingOverlayView.hidden = YES;
    
    NSString *className = NSStringFromClass(SegmentCollectionViewCell.class);
    UINib *cellNib = [UINib nibWithNibName:className bundle:nil];
    [self.timelineView registerNib:cellNib forCellWithReuseIdentifier:className];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didSkipSegment:)
                                               name:SRGMediaPlayerDidSkipBlockedSegmentNotification
                                             object:self.mediaPlayerController];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(segmentDidStart:)
                                               name:SRGMediaPlayerSegmentDidStartNotification
                                             object:self.mediaPlayerController];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(segmentDidEnd:)
                                               name:SRGMediaPlayerSegmentDidEndNotification
                                             object:self.mediaPlayerController];
    
    self.externalPlaybackSwitch.on = self.mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive;
    
    self.mediaPlayerController.view.viewMode = self.media.is360 ? SRGMediaPlayerViewModeMonoscopic : SRGMediaPlayerViewModeFlat;
    [self.mediaPlayerController playURL:self.media.URL atPosition:nil withSegments:self.media.segments userInfo:@{ @"test_field" : @"test_value" }];
}

#pragma mark UI

- (void)updateAppearanceWithTime:(CMTime)time
{
    if (self.selectedSegment) {
        time = self.selectedSegment.srg_timeRange.start;
    }
    
    for (SegmentCollectionViewCell *segmentCell in [self.timelineView visibleCells]) {
        [segmentCell updateAppearanceWithTime:time selectedSegment:self.selectedSegment];
    }
}

#pragma mark SRGTimeSliderDelegate protocol

- (void)timeSlider:(SRGTimeSlider *)slider isMovingToPlaybackTime:(CMTime)time withValue:(float)value interactive:(BOOL)interactive
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
    SegmentCollectionViewCell *segmentCell = [timelineView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(SegmentCollectionViewCell.class) forSegment:segment];
    segmentCell.segment = (DemoSegment *)segment;
    return segmentCell;
}

- (void)timelineView:(SRGTimelineView *)timelineView didSelectSegmentAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedSegment = self.media.segments[indexPath.row];
}

- (void)timelineViewDidScroll:(SRGTimelineView *)timelineView
{
    [self updateAppearanceWithTime:self.timelineSlider.time];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [[ModalTransition alloc] initForPresentation:YES];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[ModalTransition alloc] initForPresentation:NO];
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    // Return the installed interactive transition, if any
    return self.interactiveTransition;
}

#pragma mark Actions

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleExternalPlayback:(id)sender
{
    self.mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive = self.externalPlaybackSwitch.on;
}

#pragma mark Gesture recognizers

- (IBAction)pullDown:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGFloat progress = [panGestureRecognizer translationInView:self.view].y / CGRectGetHeight(self.view.frame);
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            // Avoid duplicate dismissal (which can make it impossible to dismiss the view controller altogether)
            if (self.interactiveTransition) {
                return;
            }
            
            // Install the interactive transition animation before triggering it
            self.interactiveTransition = [[ModalTransition alloc] initForPresentation:NO];
            [self dismissViewControllerAnimated:YES completion:^{
                // Only stop tracking the interactive transition at the very end. The completion block is called
                // whether the transition ended or was cancelled
                self.interactiveTransition = nil;
            }];
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            [self.interactiveTransition updateInteractiveTransitionWithProgress:progress];
            break;
        }
            
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            [self.interactiveTransition cancelInteractiveTransition];
            break;
        }
            
        case UIGestureRecognizerStateEnded: {
            // Finish the transition if the view was dragged by 20% and the user is dragging downwards
            CGFloat velocity = [panGestureRecognizer velocityInView:self.view].y;
            if (velocity > 0.f || (velocity == 0.f && progress > 0.5f)) {
                [self.interactiveTransition finishInteractiveTransition];
            }
            else {
                [self.interactiveTransition cancelInteractiveTransition];
            }
            break;
        }
            
        default: {
            break;
        }
    }
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
    
    DemoSegment *segment = notification.userInfo[SRGMediaPlayerSegmentKey];
    if (segment == self.selectedSegment) {
        self.selectedSegment = nil;
    }
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    NSLog(@"Segment did end: %@", notification.userInfo);
}

@end
