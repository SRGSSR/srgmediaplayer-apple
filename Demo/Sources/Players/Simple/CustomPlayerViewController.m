//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SimplePlayerViewController.h"

#import "NSBundle+Demo.h"
#import "SegmentCollectionViewCell.h"

@import libextobjc;
@import SRGMediaPlayer;

@interface SimplePlayerViewController ()

@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) Media *media;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet SRGTimeSlider *timelineSlider;
@property (nonatomic, weak) IBOutlet UIButton *liveButton;

@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation SimplePlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithMedia:(Media *)media
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    SimplePlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.media = media;
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.liveButton setTitle:DemoNonLocalizedString(@"Back to live") forState:UIControlStateNormal];
    self.liveButton.alpha = 0.f;
    
    self.liveButton.layer.borderColor = UIColor.whiteColor.CGColor;
    self.liveButton.layer.borderWidth = 1.f;
    
    self.mediaPlayerController.view.viewMode = self.media.is360 ? SRGMediaPlayerViewModeMonoscopic : SRGMediaPlayerViewModeFlat;
    
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
    
    if (self.movingToParentViewController || self.beingPresented) {
        [self.mediaPlayerController playURL:self.media.URL];
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
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAroundTime:CMTimeRangeGetEnd(timeRange)] withCompletionHandler:nil];
}

- (IBAction)seek:(id)sender
{
    [self updateLiveButton];
}

@end
