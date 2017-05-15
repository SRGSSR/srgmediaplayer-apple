//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TimeshiftPlayerViewController.h"

#import "SegmentCollectionViewCell.h"

#import <libextobjc/libextobjc.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface TimeshiftPlayerViewController ()

@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) NSURL *contentURL;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet SRGTimeSlider *timelineSlider;
@property (nonatomic, weak) IBOutlet UIButton *liveButton;

@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation TimeshiftPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithContentURL:(NSURL *)contentURL
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    TimeshiftPlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.contentURL = contentURL;
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.liveButton setTitle:@"Back to live" forState:UIControlStateNormal];
    self.liveButton.alpha = 0.f;

    self.liveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.liveButton.layer.borderWidth = 1.f;

    @weakify(self)
    [self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        if (self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateSeeking) {
            [self updateLiveButton];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        [self.mediaPlayerController playURL:self.contentURL];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        [self.mediaPlayerController reset];
    }
}

#pragma mark UI

- (void)updateLiveButton
{
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        [UIView animateWithDuration:0.2 animations:^{
            self.liveButton.alpha = self.timelineSlider.live ? 0.f : 1.f;
        }];
    }
    else {
        self.liveButton.alpha = 0.f;
    }
}

#pragma mark Actions

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)goToLive:(id)sender
{
    [UIView animateWithDuration:0.2 animations:^{
        self.liveButton.alpha = 0.f;
    }];

    CMTimeRange timeRange = self.mediaPlayerController.timeRange;
    if (CMTIMERANGE_IS_INDEFINITE(timeRange) || CMTIMERANGE_IS_EMPTY(timeRange)) {
        return;
    }

    [self.mediaPlayerController seekEfficientlyToTime:CMTimeRangeGetEnd(timeRange) withCompletionHandler:nil];
}

- (IBAction)seek:(id)sender
{
    [self updateLiveButton];
}

@end
