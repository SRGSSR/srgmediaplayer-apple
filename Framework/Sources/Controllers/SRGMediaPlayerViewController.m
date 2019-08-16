//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerViewController.h"

#import "NSBundle+SRGMediaPlayer.h"
#import "SRGActivityGestureRecognizer.h"
#import "SRGAirPlayButton.h"
#import "SRGAirPlayView.h"
#import "SRGMediaPlayerController.h"
#import "SRGPlaybackButton.h"
#import "SRGPictureInPictureButton.h"
#import "SRGMediaPlayerSharedController.h"
#import "SRGTimeSlider.h"
#import "SRGTracksButton.h"
#import "SRGViewModeButton.h"

#import <libextobjc/libextobjc.h>

const NSInteger SRGMediaPlayerViewControllerBackwardSkipInterval = 15.;
const NSInteger SRGMediaPlayerViewControllerForwardSkipInterval = 15.;

// Shared instance to manage picture in picture playback
static SRGMediaPlayerSharedController *s_mediaPlayerController = nil;

@interface SRGMediaPlayerViewController () <SRGTracksButtonDelegate>

@property (nonatomic, weak) IBOutlet UIView *playerView;

@property (nonatomic, weak) IBOutlet SRGTracksButton *tracksButton;
@property (nonatomic, weak) IBOutlet SRGPictureInPictureButton *pictureInPictureButton;
@property (nonatomic, weak) IBOutlet SRGViewModeButton *viewModeButton;

@property (nonatomic, weak) IBOutlet SRGPlaybackButton *playPauseButton;
@property (nonatomic, weak) IBOutlet SRGTimeSlider *timeSlider;
@property (nonatomic, weak) IBOutlet SRGAirPlayButton *airPlayButton;
@property (nonatomic, weak) IBOutlet SRGAirPlayView *airPlayView;
@property (nonatomic, weak) IBOutlet UIButton *skipBackwardButton;
@property (nonatomic, weak) IBOutlet UIButton *skipForwardButton;

@property (nonatomic, weak) IBOutlet UIImageView *errorImageView;
@property (nonatomic, weak) IBOutlet UIImageView *audioOnlyImageView;

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
    if (self != SRGMediaPlayerViewController.class) {
        return;
    }
    
    s_mediaPlayerController = [[SRGMediaPlayerSharedController alloc] init];
}

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:NSBundle.srg_mediaPlayerBundle];
    return [storyboard instantiateInitialViewController];
}

- (void)dealloc
{
    [s_mediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
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
    
    self.tracksButton.delegate = self;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(srg_mediaPlayerViewController_playbackStateDidChange:)
                                               name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                             object:s_mediaPlayerController];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(srg_mediaPlayerViewController_playbackDidFail:)
                                               name:SRGMediaPlayerPlaybackDidFailNotification
                                             object:s_mediaPlayerController];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(srg_mediaPlayerViewController_applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(srg_mediaPlayerViewController_accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusChanged
                                             object:nil];
    
    self.playerView.isAccessibilityElement = YES;
    self.playerView.accessibilityLabel = SRGMediaPlayerAccessibilityLocalizedString(@"Media", @"The player view label, where the audio / video is displayed");
    
    self.errorImageView.hidden = YES;
    self.audioOnlyImageView.hidden = YES;
    
    // Workaround UIImage view tint color bug
    // See http://stackoverflow.com/a/26042893/760435
    UIImage *errorImage = self.errorImageView.image;
    self.errorImageView.image = nil;
    self.errorImageView.image = errorImage;
    
    UIImage *audioOnlyImage = self.audioOnlyImageView.image;
    self.audioOnlyImageView.image = nil;
    self.audioOnlyImageView.image = audioOnlyImage;
    
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
    self.timeSlider.mediaPlayerController = s_mediaPlayerController;
    self.playPauseButton.mediaPlayerController = s_mediaPlayerController;
    self.airPlayButton.mediaPlayerController = s_mediaPlayerController;
    self.airPlayView.mediaPlayerController = s_mediaPlayerController;
    
    self.viewModeButton.mediaPlayerView = s_mediaPlayerController.view;
    
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
        
        [self updateUserInterface];
    }];
    [self updateUserInterface];
    
    [self updateInterfaceForControlsHidden:NO];
    [self restartInactivityTracker];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self isBeingPresented]) {
        if (s_mediaPlayerController.pictureInPictureController.pictureInPictureActive) {
            [s_mediaPlayerController.pictureInPictureController stopPictureInPicture];
        }
    }
    
    if (@available(iOS 11, *)) {
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.beingDismissed) {
        [self stopInactivityTracker];
    }
}

#pragma mark Status bar

- (BOOL)prefersStatusBarHidden
{
    return _userInterfaceHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

#pragma mark Home indicator

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return _userInterfaceHidden;
}

#pragma mark UI

- (void)updateUserInterface
{
    SRGMediaPlayerPlaybackState playbackState = s_mediaPlayerController.playbackState;
    switch (playbackState) {
        case SRGMediaPlayerPlaybackStateIdle: {
            self.timeSlider.timeLeftValueLabel.hidden = YES;
            self.timeSlider.valueLabel.hidden = YES;
            self.loadingActivityIndicatorView.hidden = YES;
            break;
        }
            
        case SRGMediaPlayerPlaybackStatePreparing: {
            self.timeSlider.timeLeftValueLabel.hidden = YES;
            self.timeSlider.valueLabel.hidden = YES;
            self.loadingActivityIndicatorView.hidden = NO;
            break;
        }
            
        case SRGMediaPlayerPlaybackStateSeeking:
        case SRGMediaPlayerPlaybackStateStalled: {
            self.timeSlider.timeLeftValueLabel.hidden = NO;
            self.timeSlider.valueLabel.hidden = YES;
            self.loadingActivityIndicatorView.hidden = NO;
            break;
        }
            
        default: {
            self.timeSlider.timeLeftValueLabel.hidden = NO;
            self.timeSlider.valueLabel.hidden = NO;
            self.loadingActivityIndicatorView.hidden = YES;
            break;
        }
    }
    
    self.skipForwardButton.hidden = ! [self canSkipForward];
    self.skipBackwardButton.hidden = ! [self canSkipBackward];
    
    if (self.controller.mediaType != SRGMediaPlayerMediaTypeAudio) {
        self.playerView.hidden = NO;
        self.audioOnlyImageView.hidden = YES;
    }
    else {
        [self updateInterfaceForControlsHidden:NO];
        
        self.playerView.hidden = YES;
        self.audioOnlyImageView.hidden = NO;
    }
}

- (void)restartInactivityTracker
{
    if (! UIAccessibilityIsVoiceOverRunning()) {
        self.inactivityTimer = [NSTimer timerWithTimeInterval:5.
                                                       target:self
                                                     selector:@selector(updateForInactivity:)
                                                     userInfo:nil
                                                      repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.inactivityTimer forMode:NSRunLoopCommonModes];
    }
    else {
        self.inactivityTimer = nil;
    }
}

- (void)stopInactivityTracker
{
    self.inactivityTimer = nil;
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
        } completion:^(BOOL finished) {
            if (@available(iOS 11, *)) {
                [self setNeedsUpdateOfHomeIndicatorAutoHidden];
            }
        }];
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

#pragma mark Skips

- (BOOL)canSkipBackward
{
    return [self canSkipBackwardFromTime:[self seekStartTime]];
}

- (BOOL)canSkipForward
{
    return [self canSkipForwardFromTime:[self seekStartTime]];
}

- (void)skipBackwardWithCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    [self skipBackwardFromTime:[self seekStartTime] withCompletionHandler:completionHandler];
}

- (void)skipForwardWithCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    [self skipForwardFromTime:[self seekStartTime] withCompletionHandler:completionHandler];
}

- (CMTime)seekStartTime
{
    return CMTIME_IS_INDEFINITE(self.controller.seekTargetTime) ? self.controller.currentTime : self.controller.seekTargetTime;
}

- (BOOL)canSkipBackwardFromTime:(CMTime)time
{
    if (CMTIME_IS_INDEFINITE(time)) {
        return NO;
    }
    
    SRGMediaPlayerController *controller = self.controller;
    SRGMediaPlayerPlaybackState playbackState = controller.playbackState;
    
    if (playbackState == SRGMediaPlayerPlaybackStateIdle || playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        return NO;
    }
    
    SRGMediaPlayerStreamType streamType = controller.streamType;
    return (streamType == SRGMediaPlayerStreamTypeOnDemand || streamType == SRGMediaPlayerStreamTypeDVR);
}

- (BOOL)canSkipForwardFromTime:(CMTime)time
{
    if (CMTIME_IS_INDEFINITE(time)) {
        return NO;
    }
    
    SRGMediaPlayerController *controller = self.controller;
    SRGMediaPlayerPlaybackState playbackState = controller.playbackState;
    
    if (playbackState == SRGMediaPlayerPlaybackStateIdle || playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        return NO;
    }
    
    SRGMediaPlayerStreamType streamType = controller.streamType;
    return (streamType == SRGMediaPlayerStreamTypeOnDemand && CMTimeGetSeconds(time) + SRGMediaPlayerViewControllerForwardSkipInterval < CMTimeGetSeconds(controller.player.currentItem.duration))
        || (streamType == SRGMediaPlayerStreamTypeDVR && ! controller.live);
}

- (void)skipBackwardFromTime:(CMTime)time withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (! [self canSkipBackwardFromTime:time]) {
        completionHandler ? completionHandler(NO) : nil;
        return;
    }
    
    CMTime targetTime = CMTimeSubtract(time, CMTimeMakeWithSeconds(SRGMediaPlayerViewControllerBackwardSkipInterval, NSEC_PER_SEC));
    [self.controller seekToPosition:[SRGPosition positionAroundTime:targetTime] withCompletionHandler:^(BOOL finished) {
        if (finished) {
            [self.controller play];
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
}

- (void)skipForwardFromTime:(CMTime)time withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (! [self canSkipForwardFromTime:time]) {
        completionHandler ? completionHandler(NO) : nil;
        return;
    }
    
    CMTime targetTime = CMTimeAdd(time, CMTimeMakeWithSeconds(SRGMediaPlayerViewControllerForwardSkipInterval, NSEC_PER_SEC));
    [self.controller seekToPosition:[SRGPosition positionAroundTime:targetTime] withCompletionHandler:^(BOOL finished) {
        if (finished) {
            [self.controller play];
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
}

#pragma mark SRGTracksButtonDelegate protocol

- (void)tracksButtonWillShowTrackSelection:(SRGTracksButton *)tracksButton
{
    [self stopInactivityTracker];
}

- (void)tracksButtonDidHideTrackSelection:(SRGTracksButton *)tracksButton
{
    [self restartInactivityTracker];
}

#pragma mark UIGestureRecognizerDelegate protocol

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [gestureRecognizer isKindOfClass:SRGActivityGestureRecognizer.class];
}

#pragma mark Notifications

- (void)srg_mediaPlayerViewController_playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
        [self updateInterfaceForControlsHidden:NO];
    }
    else if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        self.errorImageView.hidden = YES;
        [self updateUserInterface];
    }
}

- (void)srg_mediaPlayerViewController_playbackDidFail:(NSNotification *)notification
{
    self.errorImageView.hidden = NO;
    [self updateUserInterface];
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
    [self restartInactivityTracker];
}

#pragma mark Actions

- (IBAction)skipForward:(id)sender
{
    [self skipForwardWithCompletionHandler:nil];
}

- (IBAction)skipBackward:(id)sender
{
    [self skipBackwardWithCompletionHandler:nil];
}

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
    [self restartInactivityTracker];
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
    [self restartInactivityTracker];
}

#pragma mark Timers

- (void)updateForInactivity:(NSTimer *)timer
{
    [self setUserInterfaceHidden:YES animated:YES];
}

@end
