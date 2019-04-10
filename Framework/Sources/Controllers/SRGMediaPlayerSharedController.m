//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerSharedController.h"

#import "SRGMediaPlayerViewController.h"
#import "UIWindow+SRGMediaPlayer.h"

@implementation SRGMediaPlayerSharedController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.playerConfigurationBlock = ^(AVPlayer *player) {
            player.allowsExternalPlayback = (self.mediaType == SRGMediaPlayerMediaTypeVideo);
            player.usesExternalPlaybackWhileExternalScreenIsActive = YES;
        };
        
        __weak __typeof(self) weakSelf = self;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackStateDidChange:)
                                                   name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                 object:self];
    }
    return self;
}

#pragma mark Notifications

- (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerPlaybackState previousPlaybackState = [notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue];
    SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
    
    if (previousPlaybackState == SRGMediaPlayerPlaybackStatePreparing && playbackState == SRGMediaPlayerPlaybackStatePlaying) {
        [self reloadPlayerConfiguration];
    }
}

@end
