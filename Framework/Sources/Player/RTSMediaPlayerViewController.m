//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerViewController.h"

#import "NSBundle+RTSMediaPlayer.h"
#import "RTSActivityGestureRecognizer.h"
#import "RTSMediaPlayerController.h"
#import "RTSPlaybackButton.h"
#import "RTSPictureInPictureButton.h"
#import "RTSPlaybackActivityIndicatorView.h"
#import "RTSMediaPlayerSharedController.h"
#import "RTSTimeSlider.h"
#import "RTSVolumeView.h"

#import <libextobjc/EXTScope.h>

// Shared instance to manage picture in picture playback
static RTSMediaPlayerSharedController *s_mediaPlayerController = nil;

@interface RTSMediaPlayerViewController ()

@property (nonatomic) NSURL *contentURL;

@property (nonatomic, weak) IBOutlet UIView *playerView;

@property (nonatomic, weak) IBOutlet RTSPictureInPictureButton *pictureInPictureButton;
@property (nonatomic, weak) IBOutlet RTSPlaybackActivityIndicatorView *playbackActivityIndicatorView;

@property (weak) IBOutlet RTSPlaybackButton *playPauseButton;
@property (weak) IBOutlet RTSTimeSlider *timeSlider;
@property (weak) IBOutlet RTSVolumeView *volumeView;
@property (weak) IBOutlet UIButton *liveButton;

@property (weak) IBOutlet UIActivityIndicatorView *loadingActivityIndicatorView;
@property (weak) IBOutlet UILabel *loadingLabel;

@property (weak) IBOutlet NSLayoutConstraint *valueLabelWidthConstraint;
@property (weak) IBOutlet NSLayoutConstraint *timeLeftValueLabelWidthConstraint;

@property (nonatomic) IBOutletCollection(UIView) NSArray *overlayViews;

@property (nonatomic) NSTimer *inactivityTimer;

@end

@implementation RTSMediaPlayerViewController {
@private
    BOOL _userInterfaceHidden;
}

#pragma mark Class methods

+ (void)initialize
{
    if (self != [RTSMediaPlayerViewController class]) {
        return;
    }
    
    s_mediaPlayerController = [[RTSMediaPlayerSharedController alloc] init];
}

#pragma mark Object lifecycle

- (instancetype)initWithContentURL:(NSURL *)contentURL
{
    if (self = [super initWithNibName:@"RTSMediaPlayerViewController" bundle:[NSBundle rts_mediaPlayerBundle]]) {
        self.contentURL = contentURL;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithContentURL:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithContentURL:nil];
}

- (void)dealloc
{
    self.inactivityTimer = nil;                 // Invalidate timer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

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
                                             selector:@selector(mediaPlayerPlaybackStateDidChange:)
                                                 name:RTSMediaPlayerPlaybackStateDidChangeNotification
                                               object:s_mediaPlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
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
    
    RTSActivityGestureRecognizer *activityGestureRecognizer = [[RTSActivityGestureRecognizer alloc] initWithTarget:self action:@selector(resetInactivityTimer:)];
    activityGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:activityGestureRecognizer];
    
    [s_mediaPlayerController playURL:self.contentURL];
    
    self.pictureInPictureButton.mediaPlayerController = s_mediaPlayerController;
    self.playbackActivityIndicatorView.mediaPlayerController = s_mediaPlayerController;
    self.timeSlider.mediaPlayerController = s_mediaPlayerController;
    self.playPauseButton.mediaPlayerController = s_mediaPlayerController;
    
    [self.liveButton setTitle:RTSMediaPlayerLocalizedString(@"Back to live", nil) forState:UIControlStateNormal];
    self.liveButton.hidden = YES;
    
    self.liveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.liveButton.layer.borderWidth = 1.f;
    
    // Hide the time slider while the stream type is unknown (i.e. the needed slider label size cannot be determined)
    [self setTimeSliderHidden:YES];
    
    @weakify(self)
    [s_mediaPlayerController addPeriodicTimeObserverForInterval: CMTimeMakeWithSeconds(1., 5.) queue: NULL usingBlock:^(CMTime time) {
        @strongify(self)
        
        if (s_mediaPlayerController.streamType != RTSMediaStreamTypeUnknown) {
            CGFloat labelWidth = (CMTimeGetSeconds(s_mediaPlayerController.timeRange.duration) >= 60. * 60.) ? 56.f : 45.f;
            self.valueLabelWidthConstraint.constant = labelWidth;
            self.timeLeftValueLabelWidthConstraint.constant = labelWidth;
            
            if (s_mediaPlayerController.playbackState != RTSPlaybackStateSeeking) {
                [self updateLiveButton];
            }
            
            [self setTimeSliderHidden:NO];
        }
        else {
            [self setTimeSliderHidden:YES];
        }
    }];
    
    [self resetInactivityTimer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (s_mediaPlayerController.pictureInPictureController.pictureInPictureActive) {
        [s_mediaPlayerController.pictureInPictureController stopPictureInPicture];
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

#pragma mark UI

- (void)setTimeSliderHidden:(BOOL)hidden
{
    self.timeSlider.timeLeftValueLabel.hidden = hidden;
    self.timeSlider.valueLabel.hidden = hidden;
    self.timeSlider.hidden = hidden;
    
    self.loadingActivityIndicatorView.hidden = ! hidden;
    if (hidden) {
        [self.loadingActivityIndicatorView startAnimating];
    }
    else {
        [self.loadingActivityIndicatorView stopAnimating];
    }
    self.loadingLabel.hidden = ! hidden;
}

- (void)updateLiveButton
{
    if (s_mediaPlayerController.streamType == RTSMediaStreamTypeDVR) {
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
    self.inactivityTimer = [NSTimer scheduledTimerWithTimeInterval:5.
                                                            target:self
                                                          selector:@selector(updateForInactivity:)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated
{
    void (^animations)(void) = ^{
        [self setNeedsStatusBarAppearanceUpdate];
        
        for (UIView *view in self.overlayViews) {
            view.alpha = hidden ? 0.f : 1.f;
        }
    };
    
    _userInterfaceHidden = hidden;
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations completion:nil];
    }
    else {
        animations();
    }
}

#pragma mark UIGestureRecognizerDelegate protocol

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [gestureRecognizer isKindOfClass:[RTSActivityGestureRecognizer class]];
}

#pragma mark Notifications

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
    RTSMediaPlayerController *mediaPlayerController = notification.object;
    if (mediaPlayerController.playbackState == RTSPlaybackStateEnded) {
        [self dismiss:nil];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    AVPictureInPictureController *pictureInPictureController = s_mediaPlayerController.pictureInPictureController;
    
    if (pictureInPictureController.isPictureInPictureActive) {
        [pictureInPictureController stopPictureInPicture];
    }
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
    
    [s_mediaPlayerController seekToTime:CMTimeRangeGetEnd(timeRange) completionHandler:^(BOOL finished) {
        if (finished) {
            [s_mediaPlayerController togglePlayPause];
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
