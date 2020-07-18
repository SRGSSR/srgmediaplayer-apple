//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SimplePlayerViewController.h"

#import "Resources.h"
#import "SegmentCollectionViewCell.h"

@import libextobjc;
@import MAKVONotificationCenter;
@import SRGMediaPlayer;

@interface SimplePlayerViewController ()

@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;     // top-level object, retained

@property (nonatomic) Media *media;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet SRGTimeSlider *timeSlider;
@property (nonatomic, weak) IBOutlet UIButton *liveButton;

@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation SimplePlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithMedia:(Media *)media
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:ResourceNameForUIClass(self.class) bundle:nil];
    SimplePlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.media = media;
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.liveButton setTitle:NSLocalizedString(@"Back to live", nil) forState:UIControlStateNormal];
    self.liveButton.alpha = 0.f;
    
    self.liveButton.layer.borderColor = UIColor.whiteColor.CGColor;
    self.liveButton.layer.borderWidth = 1.f;
    
    self.mediaPlayerController.view.viewMode = self.media.is360 ? SRGMediaPlayerViewModeMonoscopic : SRGMediaPlayerViewModeFlat;
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, live) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        [self updateLiveButton];
    }];
    [self updateLiveButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.movingToParentViewController || self.beingPresented) {
        [self.mediaPlayerController playURL:self.media.URL];
    }
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark UI

- (void)updateLiveButton
{
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        [UIView animateWithDuration:0.2 animations:^{
            self.liveButton.alpha = self.mediaPlayerController.live ? 0.f : 1.f;
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

@end
