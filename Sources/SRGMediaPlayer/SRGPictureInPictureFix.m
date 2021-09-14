//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import AVKit;
@import UIKit;

#import "UIApplication+SRGMediaPlayer.h"

@interface SRGDummyPlayerViewController : AVPlayerViewController
    
@end

@implementation SRGDummyPlayerViewController

- (UIView *)view
{
    UIView *view = super.view;
    view.hidden = YES;
    return view;
}

@end

@interface SRGPictureInPictureFix : NSObject

@end

@implementation SRGPictureInPictureFix

- (instancetype)init
{
    if (self = [super init]) {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationDidBecomeActive:)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
    }
    return self;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        // iOS 14 regression: Using `AVPictureInPictureController` leaks an `AVPlayer`instance even afer the
        // app released all strong references (reported as FB8561088).
        // Somehow Apple manages to circumvent this issue internally with `AVPlayerViewController` which, if
        // displayed once, ensures proper behavior afterwards.
        SRGDummyPlayerViewController *playerViewController = [[SRGDummyPlayerViewController alloc] init];
        playerViewController.player = [AVPlayer new];
        
        UIView *playerView = playerViewController.view;
        UIWindow *mainWindow = UIApplication.sharedApplication.srgmediaplayer_mainWindow;
        [mainWindow addSubview:playerView];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [playerView removeFromSuperview];
        });
    });
}

@end

static SRGPictureInPictureFix *s_pictureInPictureFix;

__attribute__((constructor)) void SRGPictureInPictureFixInit(void)
{
    if (@available(iOS 14, tvOS 14, *)) {
        s_pictureInPictureFix = [[SRGPictureInPictureFix alloc] init];
    }
}
