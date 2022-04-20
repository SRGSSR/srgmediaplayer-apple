//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "InlinePlayerViewController.h"

#import "Resources.h"

@import libextobjc;
@import MAKVONotificationCenter;
@import SRGMediaPlayer;

@interface InlinePlayerViewController ()

@property (nonatomic) Media *media;

@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;         // top object, strong
@property (nonatomic, getter=isReady) BOOL ready;

@property (nonatomic, weak) IBOutlet UIView *playerHostView;
@property (nonatomic, weak) IBOutlet UIStackView *sleepSettingStackView;
@property (nonatomic, weak) IBOutlet UILabel *sleepResultLabel;

@end

@implementation InlinePlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithMedia:(Media *)media
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:ResourceNameForUIClass(self.class) bundle:nil];
    InlinePlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.media = media;
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (@available(iOS 12, *)) {
        @weakify(self)
        [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, player.preventsDisplaySleepDuringVideoPlayback) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateSleepResultLabel];
        }];
        [self updateSleepResultLabel];
    }
    else {
        self.sleepResultLabel.hidden = YES;
    }
        
    if (@available(iOS 12, *)) {
        self.sleepSettingStackView.hidden = NO;
    }
    else {
        self.sleepSettingStackView.hidden = YES;
    }
    
    [self attachPlayerView];
}

#pragma mark View management

- (void)attachPlayerView
{
    UIView *playerView = self.mediaPlayerController.view;
    [self.playerHostView insertSubview:playerView atIndex:0];
    
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [playerView.topAnchor constraintEqualToAnchor:self.playerHostView.topAnchor],
        [playerView.bottomAnchor constraintEqualToAnchor:self.playerHostView.bottomAnchor],
        [playerView.leadingAnchor constraintEqualToAnchor:self.playerHostView.leadingAnchor],
        [playerView.trailingAnchor constraintEqualToAnchor:self.playerHostView.trailingAnchor]
    ]];
}

- (void)detachPlayerView
{
    [self.mediaPlayerController.view removeFromSuperview];
}

#pragma mark UI

- (void)updateSleepResultLabel API_AVAILABLE(ios(12.0))
{
    self.sleepResultLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Current value: %@", nil), self.mediaPlayerController.player.preventsDisplaySleepDuringVideoPlayback ? @"YES" : @"NO"];
}

#pragma mark Actions

- (IBAction)prepareToPlay:(id)sender
{
    self.mediaPlayerController.view.viewMode = self.media.is360 ? SRGMediaPlayerViewModeMonoscopic : SRGMediaPlayerViewModeFlat;
    [self.mediaPlayerController prepareToPlayURL:self.media.URL atPosition:nil withSegments:nil userInfo:nil completionHandler:^{
        self.ready = YES;
    }];
}

- (IBAction)togglePlayPause:(id)sender
{
    if (self.ready) {
        [self.mediaPlayerController togglePlayPause];
    }
    else {
        [self.mediaPlayerController prepareToPlayURL:self.media.URL atPosition:nil withSegments:nil userInfo:nil completionHandler:^{
            self.ready = YES;
            [self.mediaPlayerController play];
        }];
    }
}

- (IBAction)reset:(id)sender
{
    self.ready = NO;
    [self.mediaPlayerController reset];
}

- (IBAction)toggleAttached:(id)sender
{
    if (self.mediaPlayerController.view.superview) {
        [self detachPlayerView];
    }
    else {
        [self attachPlayerView];
    }
}

- (IBAction)toggleVideoPlaybackPreventsDeviceSleep:(UISwitch *)preventsDeviceSleepSwitch
{
    if (@available(iOS 12, *)) {
        self.mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
            player.preventsDisplaySleepDuringVideoPlayback = preventsDeviceSleepSwitch.on;
        };
        [self.mediaPlayerController reloadPlayerConfiguration];
    }
}

- (IBAction)selectViewBackgroundBehavior:(UISegmentedControl *)segmentedControl
{
    switch (segmentedControl.selectedSegmentIndex) {
        case 0: {
            self.mediaPlayerController.viewBackgroundBehavior = SRGMediaPlayerViewBackgroundBehaviorAttached;
            break;
        }
            
        case 1: {
            self.mediaPlayerController.viewBackgroundBehavior = SRGMediaPlayerViewBackgroundBehaviorDetached;
            break;
        }
            
        case 2: {
            self.mediaPlayerController.viewBackgroundBehavior = SRGMediaPlayerViewBackgroundBehaviorDetachedWhenDeviceLocked;
            break;
        }
            
        default: {
            break;
        }
    }
}

- (IBAction)reloadPlayerConfiguration:(id)sender
{
    [self.mediaPlayerController reloadPlayerConfiguration];
}

@end
