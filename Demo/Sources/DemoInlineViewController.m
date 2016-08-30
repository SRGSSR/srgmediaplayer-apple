//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemoInlineViewController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface DemoInlineViewController ()

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;         // top object, strong

@end

@implementation DemoInlineViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mediaPlayerController.view.frame = self.videoContainerView.bounds;
    self.mediaPlayerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.videoContainerView insertSubview:self.mediaPlayerController.view atIndex:0];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([self isMovingFromParentViewController]) {
        [self.mediaPlayerController reset];
    }
}

#pragma mark - Actions

- (IBAction)prepareToPlay:(id)sender
{
    [self.mediaPlayerController prepareToPlayURL:self.mediaURL atTime:kCMTimeZero withCompletionHandler:nil];
}

- (IBAction)togglePlayPause:(id)sender
{
    [self.mediaPlayerController togglePlayPause];
}

- (IBAction)reset:(id)sender
{
    [self.mediaPlayerController reset];
}

@end
