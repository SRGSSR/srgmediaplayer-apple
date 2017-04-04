//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "InlinePlayerViewController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface InlinePlayerViewController ()

@property (nonatomic) NSURL *contentURL;
@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;         // top object, strong

@end

@implementation InlinePlayerViewController {
@private
    BOOL _ready;
}

#pragma mark Object lifecycle

- (instancetype)initWithContentURL:(NSURL *)contentURL
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    InlinePlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.contentURL = contentURL;
    return viewController;
}

#pragma mark View lifecycle

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
    [self.mediaPlayerController prepareToPlayURL:self.contentURL atTime:kCMTimeZero withSegments:nil userInfo:nil completionHandler:^{
        _ready = YES;
    }];
}

- (IBAction)togglePlayPause:(id)sender
{
    if (_ready) {
        [self.mediaPlayerController togglePlayPause];
    }
    else {
        [self.mediaPlayerController playURL:self.contentURL];
    }
}

- (IBAction)reset:(id)sender
{
    _ready = NO;
    [self.mediaPlayerController reset];
}

@end
