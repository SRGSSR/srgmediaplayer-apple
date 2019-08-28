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

@end

@implementation InlinePlayerViewController {
@private
    BOOL _ready;
}

#pragma mark Object lifecycle

- (instancetype)initWithMedia:(Media *)media
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:ResourceNameForUIClass(self.class) bundle:nil];
    InlinePlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.media = media;
    return viewController;
}

#pragma mark Actions

- (IBAction)prepareToPlay:(id)sender
{
    self.mediaPlayerController.view.viewMode = self.media.is360 ? SRGMediaPlayerViewModeMonoscopic : SRGMediaPlayerViewModeFlat;
    [self.mediaPlayerController prepareToPlayURL:self.media.URL atPosition:nil withSegments:nil userInfo:nil completionHandler:^{
        self->_ready = YES;
    }];
}

- (IBAction)togglePlayPause:(id)sender
{
    if (_ready) {
        [self.mediaPlayerController togglePlayPause];
    }
    else {
        [self.mediaPlayerController playURL:self.media.URL];
    }
}

- (IBAction)reset:(id)sender
{
    _ready = NO;
    [self.mediaPlayerController reset];
}

@end
