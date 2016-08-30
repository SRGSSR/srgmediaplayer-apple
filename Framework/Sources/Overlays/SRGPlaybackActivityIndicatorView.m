//
//  Copyright (c) SRG. All rights reserved.
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    if (mediaPlayerController) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateUponPlaybackStateChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:mediaPlayerController];
    }
    
    [self updateWithMediaPlayerController:mediaPlayerController];
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];

    if (newWindow) {
        [self updateWithMediaPlayerController:self.mediaPlayerController];
    }
}

#pragma mark UI

- (void)updateWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (mediaPlayerController.playbackState == SRGPlaybackStatePlaying
            || mediaPlayerController.playbackState == SRGPlaybackStatePaused
            || mediaPlayerController.playbackState == SRGPlaybackStateEnded
            || mediaPlayerController.playbackState == SRGPlaybackStateIdle) {
        [self stopAnimating];
    }
    else {
        [self startAnimating];
    }
}

#pragma mark Notifications

- (void)updateUponPlaybackStateChange:(NSNotification *)notif
{
    [self updateWithMediaPlayerController:self.mediaPlayerController];
}

@end

#pragma mark Static functions

static void commonInit(SRGPlaybackActivityIndicatorView *self)
{
    self.hidesWhenStopped = YES;
    [self stopAnimating];
}
