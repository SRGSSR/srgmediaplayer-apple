//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSPlaybackActivityIndicatorView.h"
#import "RTSMediaPlayerController.h"

@implementation RTSPlaybackActivityIndicatorView

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
    self.hidden = (mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying ||
                   mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused ||
                   mediaPlayerController.playbackState == RTSMediaPlaybackStateEnded);
}

@end
