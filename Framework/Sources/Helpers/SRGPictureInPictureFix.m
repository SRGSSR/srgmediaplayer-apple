//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import AVKit;
@import Foundation;
@import UIKit;

@interface SRGPictureInPictureFix: NSObject

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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // iOS 14 regression: Using `AVPictureInPictureController` leaks an `AVPlayer`instance even afer the
        // app released all strong references (reported as FB8561088).
        // Somehow Apple manages to circumvent this issue internally with `AVPlayerViewController` which, if
        // displayed once, ensures proper behavior afterwards.
        AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
        playerViewController.player = [AVPlayer new];
        
        UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
        [rootViewController presentViewController:playerViewController animated:NO completion:^{
            [rootViewController dismissViewControllerAnimated:NO completion:nil];
        }];
    });
}

@end

static SRGPictureInPictureFix *s_pictureInPictureFix;

__attribute__ ((constructor)) void SRGPictureInPictureFixInit(void)
{
    if (@available(iOS 14, *)) {
        s_pictureInPictureFix = [[SRGPictureInPictureFix alloc] init];
    }
}
