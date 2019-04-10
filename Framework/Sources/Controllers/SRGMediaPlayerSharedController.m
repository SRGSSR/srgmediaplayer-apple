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
        
#if TARGET_OS_IOS
        __weak __typeof(self) weakSelf = self;
        self.pictureInPictureControllerCreationBlock = ^(AVPictureInPictureController *pictureInPictureController) {
            pictureInPictureController.delegate = weakSelf;
        };
#endif
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackStateDidChange:)
                                                   name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                 object:self];
    }
    return self;
}

#if TARGET_OS_IOS

#pragma mark AVPictureInPictureControllerDelegate protocol

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    // SRGMediaPlayerViewController is always displayed modally, the following therefore always works
    UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
    [rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.srg_topViewController;
    
    // If no SRGMediaPlayerViewController instance is currently displayed (always modally)
    if (topViewController && ! [topViewController isKindOfClass:SRGMediaPlayerViewController.class]) {
        // FIXME: Init with controller
        SRGMediaPlayerViewController *mediaPlayerViewController = [[SRGMediaPlayerViewController alloc] init];
        mediaPlayerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [topViewController presentViewController:mediaPlayerViewController animated:YES completion:^{
            // See comment above
            completionHandler(YES);
        }];
    }
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    // Reset the status of the player when picture in picture is exited anywhere except from the SRGMediaPlayerViewController
    // itself
    UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.srg_topViewController;
    if (! [topViewController isKindOfClass:SRGMediaPlayerViewController.class]) {
        [self reset];
    }
}

#endif

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
