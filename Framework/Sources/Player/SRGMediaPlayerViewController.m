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
@property (nonatomic, weak) IBOutlet UIButton *skipBackButton;
@property (nonatomic, weak) IBOutlet UIButton *skipForwardButton;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingActivityIndicatorView;

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
    
    // The frame of an activity indicator cannot be changed. Use a transform.
    self.loadingActivityIndicatorView.transform = CGAffineTransformMakeScale(0.6f, 0.6f);
    [self.loadingActivityIndicatorView startAnimating];
    
    for (UIView *view in self.overlayViews) {
        view.layer.cornerRadius = 10.f;
        view.clipsToBounds = YES;
    }
    
    @weakify(self)
    self.periodicTimeObserver = [s_mediaPlayerController addPeriodicTimeObserverForInterval: CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue: NULL usingBlock:^(CMTime time) {
        @strongify(self)
        
        [self updateControls];
    }];
    [self updateControls];
    
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

- (void)updateControls
{
    SRGMediaPlayerPlaybackState playbackState = s_mediaPlayerController.playbackState;
    
    if (playbackState == SRGMediaPlayerPlaybackStateIdle || playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        self.timeSlider.timeLeftValueLabel.hidden = YES;
        self.timeSlider.valueLabel.hidden = YES;
        self.loadingActivityIndicatorView.hidden = (playbackState != SRGMediaPlayerPlaybackStatePreparing);
    }
    else {
        self.timeSlider.timeLeftValueLabel.hidden = NO;
        self.timeSlider.valueLabel.hidden = NO;
        self.loadingActivityIndicatorView.hidden = YES;
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
    
    [self updateControls];
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
