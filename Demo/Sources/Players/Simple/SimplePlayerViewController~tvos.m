//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SimplePlayerViewController.h"

#import "Resources.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface SimplePlayerViewController ()

@property (nonatomic) Media *media;

@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;
@property (nonatomic, weak) IBOutlet SRGMediaPlayerView *mediaPlayerView;

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
    
    self.mediaPlayerView.viewMode = self.media.is360 ? SRGMediaPlayerViewModeMonoscopic : SRGMediaPlayerViewModeFlat;
    
    [self.mediaPlayerController playURL:self.media.URL];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayPause:)];
    tapGestureRecognizer.allowedPressTypes = @[ @(UIPressTypeSelect), @(UIPressTypePlayPause) ];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

#pragma mark Gesture recognizers

- (void)togglePlayPause:(UIGestureRecognizer *)gestureRecognizer
{
    [self.mediaPlayerController togglePlayPause];
}

@end
