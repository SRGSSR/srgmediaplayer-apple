//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPlaybackActivityIndicatorView.h"

static void commonInit(SRGPlaybackActivityIndicatorView *self);

@implementation SRGPlaybackActivityIndicatorView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                      object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self updateAppearanceForMediaPlayerController:mediaPlayerController];
    
    if (mediaPlayerController) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateUponPlaybackStateChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:mediaPlayerController];
    }
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];

    if (newWindow) {
        [self updateAppearanceForMediaPlayerController:self.mediaPlayerController];
    }
}

#pragma mark UI

- (void)updateAppearanceForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePaused
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        [self stopAnimating];
    }
    else {
        [self startAnimating];
    }
}

#pragma mark Notifications

- (void)updateUponPlaybackStateChange:(NSNotification *)notif
{
    [self updateAppearanceForMediaPlayerController:self.mediaPlayerController];
}

@end

#pragma mark Static functions

static void commonInit(SRGPlaybackActivityIndicatorView *self)
{
    self.hidesWhenStopped = YES;
    [self stopAnimating];
}
