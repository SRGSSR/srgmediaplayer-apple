//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSPlaybackActivityIndicatorView.h"

static void commonInit(RTSPlaybackActivityIndicatorView *self);

@implementation RTSPlaybackActivityIndicatorView

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

- (void)setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:RTSMediaPlayerPlaybackStateDidChangeNotification
                                                      object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    
    if (mediaPlayerController) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateUponPlaybackStateChange:)
                                                     name:RTSMediaPlayerPlaybackStateDidChangeNotification
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

- (void)updateWithMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    if (mediaPlayerController.playbackState == RTSPlaybackStatePlaying
            || mediaPlayerController.playbackState == RTSPlaybackStatePaused
            || mediaPlayerController.playbackState == RTSPlaybackStateEnded
            || mediaPlayerController.playbackState == RTSPlaybackStateIdle) {
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

static void commonInit(RTSPlaybackActivityIndicatorView *self)
{
    self.hidesWhenStopped = YES;
    [self stopAnimating];
}
