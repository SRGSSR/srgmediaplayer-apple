//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSPlaybackActivityIndicatorView.h"
#import "RTSMediaPlayerController.h"

static void commonInit(RTSPlaybackActivityIndicatorView *self);

@implementation RTSPlaybackActivityIndicatorView

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

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateUponPlaybackStateChange:(NSNotification *)notif
{
	[self updateWithMediaPlayerController:self.mediaPlayerController];
}

- (void)updateWithMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    if (mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying ||
            mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused ||
            mediaPlayerController.playbackState == RTSMediaPlaybackStateEnded) {
        [self stopAnimating];
    }
    else {
        [self startAnimating];
    }
}

@end

static void commonInit(RTSPlaybackActivityIndicatorView *self)
{
    self.hidesWhenStopped = YES;
    [self stopAnimating];
}
