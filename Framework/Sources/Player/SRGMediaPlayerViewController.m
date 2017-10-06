//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerViewController.h"

#import "NSBundle+SRGMediaPlayer.h"
#import "SRGActivityGestureRecognizer.h"
#import "SRGAirplayButton.h"
#import "SRGAirplayView.h"
#import "SRGMediaPlayerController.h"
#import "SRGPlaybackButton.h"
#import "SRGPictureInPictureButton.h"
#import "SRGPlaybackActivityIndicatorView.h"
#import "SRGMediaPlayerSharedController.h"
#import "SRGTimeSlider.h"
#import "SRGTracksButton.h"
#import "SRGVolumeView.h"

#import <libextobjc/libextobjc.h>

// Shared instance to manage picture in picture playback
static SRGMediaPlayerSharedController *s_mediaPlayerController = nil;

@interface SRGMediaPlayerViewController ()

@property (nonatomic, weak) IBOutlet UIView *playerView;

@property (nonatomic, weak) IBOutlet SRGTracksButton *tracksButton;
@property (nonatomic, weak) IBOutlet SRGPictureInPictureButton *pictureInPictureButton;
@property (nonatomic, weak) IBOutlet SRGPlaybackActivityIndicatorView *playbackActivityIndicatorView;

@property (nonatomic, weak) IBOutlet SRGPlaybackButton *playPauseButton;
@property (nonatomic, weak) IBOutlet SRGTimeSlider *timeSlider;
@property (nonatomic, weak) IBOutlet SRGVolumeView *volumeView;
@property (nonatomic, weak) IBOutlet SRGAirplayButton *airplayButton;
@property (nonatomic, weak) IBOutlet SRGAirplayView *airplayView;
@property (nonatomic, weak) IBOutlet UIButton *liveButton;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingActivityIndicatorView;
@property (nonatomic, weak) IBOutlet UILabel *loadingLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *valueLabelWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *timeLeftValueLabelWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomPlayerViewConstraint;

@property (nonatomic) IBOutletCollection(UIView) NSArray *overlayViews;

@property (nonatomic) NSTimer *inactivityTimer;

@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation SRGMediaPlayerViewController {
@private
    BOOL _userInterfaceHidden;
}

#pragma mark Class methods

+ (void)initialize
{
    if (self != [SRGMediaPlayerViewController class]) {
        return;
    }
    
    s_mediaPlayerController = [[SRGMediaPlayerSharedController alloc] init];
}

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:[NSBundle srg_mediaPlayerBundle]];
    return [storyboard instantiateInitialViewController];
}

- (void)dealloc
{
    self.inactivityTimer = nil;                 // Invalidate timer
    [s_mediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

- (SRGMediaPlayerController *)controller
{
    return s_mediaPlayerController;
}

- (void)setInactivityTimer:(NSTimer *)inactivityTimer
{
    [_inactivityTimer invalidate];
    _inactivityTimer = inactivityTimer;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(srg_mediaPlayerViewController_playbackStateDidChange:)
                                                 name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                               object:s_mediaPlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(srg_mediaPlayerViewController_applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(srg_mediaPlayerViewController_accessibilityVoiceOverStatusChanged:)
                                                 name:UIAccessibilityVoiceOverStatusChanged
                                               object:nil];
    
    self.playerView.isAccessibilityElement = YES;
    self.playerView.accessibilityLabel = SRGMediaPlayerAccessibilityLocalizedString(@"Media", @"The player view label, where the audio / video is displayed");

    
    // Use a wrapper to avoid setting gesture recognizers widely on the shared player instance view
    s_mediaPlayerController.view.frame = self.playerView.bounds;
    s_mediaPlayerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.playerView addSubview:s_mediaPlayerController.view];
    
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.playerView addGestureRecognizer:doubleTapGestureRecognizer];
    
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    [self.playerView addGestureRecognizer:singleTapGestureRecognizer];
    
    SRGActivityGestureRecognizer *activityGestureRecognizer = [[SRGActivityGestureRecognizer alloc] initWithTarget:self action:@selector(resetInactivityTimer:)];
    activityGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:activityGestureRecognizer];
    
    self.pictureInPictureButton.mediaPlayerController = s_mediaPlayerController;
    self.tracksButton.mediaPlayerController = s_mediaPlayerController;
    self.playbackActivityIndicatorView.mediaPlayerController = s_mediaPlayerController;
    self.timeSlider.mediaPlayerController = s_mediaPlayerController;
    self.playPauseButton.mediaPlayerController = s_mediaPlayerController;
    self.airplayButton.mediaPlayerController = s_mediaPlayerController;
    self.airplayView.mediaPlayerController = s_mediaPlayerController;
    
    [self.liveButton setTitle:SRGMediaPlayerLocalizedString(@"Back to live", @"Button title to go back to live") forState:UIControlStateNormal];
    self.liveButton.accessibilityLabel = SRGMediaPlayerAccessibilityLocalizedString(@"Back to live", @"Back to live label");
    self.liveButton.hidden = YES;
    
    self.liveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.liveButton.layer.borderWidth = 1.f;
    
    @weakify(self)
    self.periodicTimeObserver = [s_mediaPlayerController addPeriodicTimeObserverForInterval: CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue: NULL usingBlock:^(CMTime time) {
        @strongify(self)
        
        if (s_mediaPlayerController.streamType != SRGMediaPlayerStreamTypeUnknown) {
            CGFloat labelWidth = (CMTimeGetSeconds(s_mediaPlayerController.timeRange.duration) >= 60. * 60.) ? 56.f : 45.f;
            self.valueLabelWidthConstraint.constant = labelWidth;
            self.timeLeftValueLabelWidthConstraint.constant = labelWidth;
            
            if (s_mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateSeeking) {
                [self updateLiveButton];
            }
        }
        
        [self updateTopBar];
    }];
    [self updateTopBar];
    
    [self updateInterfaceForControlsHidden:NO];
    [self resetInactivityTimer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self isBeingPresented]) {
        if (s_mediaPlayerController.pictureInPictureController.pictureInPictureActive) {
            [s_mediaPlayerController.pictureInPictureController stopPictureInPicture];
        }
        // We might restore the view controller at the end of playback in picture in picture mode (see
        // srg_mediaPlayerViewController_playbackStateDidChange:). In this case, we close the view controller
        // automatically, as is done when playing in full screen. We just wait one second to let restoration
        // finish (visually)
        else if (s_mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismiss:nil];
            });
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self isBeingDismissed]) {
        self.inactivityTimer = nil;
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (@available(iOS 11.0, *)) {
        self.bottomPlayerViewConstraint.constant = -self.view.safeAreaInsets.bottom;
    }
}

#pragma mark Status bar

- (BOOL)prefersStatusBarHidden
{
    return _userInterfaceHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

#pragma mark UI

- (void)updateTopBar
{
    SRGMediaPlayerPlaybackState playbackState = s_mediaPlayerController.playbackState;
    
    if (playbackState == SRGMediaPlayerPlaybackStateIdle || playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        self.timeSlider.timeLeftValueLabel.hidden = YES;
        self.timeSlider.valueLabel.hidden = YES;
        self.timeSlider.hidden = YES;
        
        if (playbackState == SRGMediaPlayerPlaybackStatePreparing) {
            self.loadingLabel.hidden = NO;
            self.loadingActivityIndicatorView.hidden = NO;
            [self.loadingActivityIndicatorView startAnimating];
        }
        else {
            self.loadingLabel.hidden = YES;
            self.loadingActivityIndicatorView.hidden = YES;
            [self.loadingActivityIndicatorView stopAnimating];
        }
    }
    else {
        self.timeSlider.timeLeftValueLabel.hidden = NO;
        self.timeSlider.valueLabel.hidden = NO;
        self.timeSlider.hidden = NO;
        
        self.loadingLabel.hidden = YES;
        self.loadingActivityIndicatorView.hidden = YES;
        [self.loadingActivityIndicatorView stopAnimating];
    }
}

- (void)updateLiveButton
{
    if (s_mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        [UIView animateWithDuration:0.2 animations:^{
            self.liveButton.hidden = self.timeSlider.live;
        }];
    }
    else {
        self.liveButton.hidden = YES;
    }
}

- (void)resetInactivityTimer
{
    self.inactivityTimer = (! UIAccessibilityIsVoiceOverRunning()) ? [NSTimer scheduledTimerWithTimeInterval:5.
                                                                                                      target:self
                                                                                                    selector:@selector(updateForInactivity:)
                                                                                                    userInfo:nil
                                                                                                     repeats:NO] : nil;
}

- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated
{
    void (^animations)(void) = ^{
        [self updateInterfaceForControlsHidden:hidden];
    };
    
    _userInterfaceHidden = hidden;
    
    if (animated) {
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.2 animations:^{
            animations();
            [self.view layoutIfNeeded];
        } completion:nil];
    }
    else {
        animations();
    }
}

- (void)updateInterfaceForControlsHidden:(BOOL)hidden
{
    [self setNeedsStatusBarAppearanceUpdate];
    
    for (UIView *view in self.overlayViews) {
        view.alpha = hidden ? 0.f : 1.f;
    }
}

#pragma mark UIGestureRecognizerDelegate protocol

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [gestureRecognizer isKindOfClass:[SRGActivityGestureRecognizer class]];
}

#pragma mark Notifications

- (void)srg_mediaPlayerViewController_playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    
    // Dismiss any video overlay (full screen or picture in picture) when playback normally ends
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
        if (s_mediaPlayerController.pictureInPictureController.isPictureInPictureActive) {
            [s_mediaPlayerController.pictureInPictureController stopPictureInPicture];
        }
        else {
            [self dismiss:nil];
        }
    }
    
    [self updateTopBar];
}

- (void)srg_mediaPlayerViewController_applicationDidBecomeActive:(NSNotification *)notification
{
    AVPictureInPictureController *pictureInPictureController = s_mediaPlayerController.pictureInPictureController;
    
    if (pictureInPictureController.isPictureInPictureActive) {
        [pictureInPictureController stopPictureInPicture];
    }
}

- (void)srg_mediaPlayerViewController_accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self resetInactivityTimer];
}

#pragma mark Actions

- (IBAction)dismiss:(id)sender
{
    if (! s_mediaPlayerController.pictureInPictureController.isPictureInPictureActive) {
        [s_mediaPlayerController reset];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)goToLive:(id)sender
{
    self.liveButton.hidden = YES;
    
    CMTimeRange timeRange = s_mediaPlayerController.timeRange;
    if (CMTIMERANGE_IS_INDEFINITE(timeRange) || CMTIMERANGE_IS_EMPTY(timeRange)) {
        return;
    }
    
    [s_mediaPlayerController seekEfficientlyToTime:CMTimeRangeGetEnd(timeRange) withCompletionHandler:^(BOOL finished) {
        if (finished) {
            [s_mediaPlayerController play];
        }
    }];
}

- (IBAction)seek:(id)sender
{
    [self updateLiveButton];
}

#pragma mark Gesture recognizers

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
    [self resetInactivityTimer];
    [self setUserInterfaceHidden:! _userInterfaceHidden animated:YES];
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    AVPlayerLayer *playerLayer = s_mediaPlayerController.playerLayer;
    
    if ([playerLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    else {
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
}

- (void)resetInactivityTimer:(UIGestureRecognizer *)gestureRecognizer
{
    [self resetInactivityTimer];
}

#pragma mark Timers

- (void)updateForInactivity:(NSTimer *)timer
{
    [self setUserInterfaceHidden:YES animated:YES];
}

@end
