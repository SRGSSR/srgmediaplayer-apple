//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemoInlineViewController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface DemoInlineViewController ()

@property (nonatomic) NSURL *contentURL;
@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic) IBOutlet SRGMediaPlayerController *mediaPlayerController;         // top object, strong

@end

@implementation DemoInlineViewController {
@private
    BOOL _ready;
}

#pragma mark Object lifecycle

- (instancetype)initWithContentURL:(NSURL *)contentURL
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    DemoInlineViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.contentURL = contentURL;
    return viewController;
}

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
    [self.mediaPlayerController prepareToPlayURL:self.contentURL atTime:kCMTimeZero withCompletionHandler:^(BOOL finished) {
        if (finished) {
            _ready = YES;
        }
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
