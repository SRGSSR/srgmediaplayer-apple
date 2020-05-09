//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "InlinePlayerViewController.h"

#import "Resources.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface InlinePlayerViewController ()

@property (nonatomic) Media *media;

@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;         // top object, strong
@property (nonatomic, getter=isReady) BOOL ready;

@property (nonatomic, weak) IBOutlet UIView *playerHostView;
@property (nonatomic, weak) IBOutlet UIStackView *sleepSettingStackView;

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
    
    if (@available(iOS 12.0, *)) {
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
    self.mediaPlayerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mediaPlayerController.view.frame = self.playerHostView.bounds;
    [self.playerHostView insertSubview:self.mediaPlayerController.view atIndex:0];
}

- (void)detachPlayerView
{
    [self.mediaPlayerController.view removeFromSuperview];
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
        [self.mediaPlayerController playURL:self.media.URL];
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

- (IBAction)toggleVideoPlaybackPreventsDeviceSleep:(id)sender
{
    if (@available(iOS 12.0, *)) {
        self.mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
            player.preventsDisplaySleepDuringVideoPlayback = ! player.preventsDisplaySleepDuringVideoPlayback;
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

@end
