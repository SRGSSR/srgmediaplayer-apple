//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSPlaybackActivityIndicatorView.h"

#import "RTSMediaPlayerController.h"

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
    if (mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying
            || mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused
            || mediaPlayerController.playbackState == RTSMediaPlaybackStateEnded
            || mediaPlayerController.playbackState == RTSMediaPlaybackStateIdle) {
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
