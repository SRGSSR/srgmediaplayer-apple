//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerSharedController.h"

#import "RTSMediaPlayerViewController.h"

@implementation RTSMediaPlayerSharedController

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler
{
	if (! self.currentViewController) {
		RTSMediaPlayerViewController *mediaPlayerViewController = [[RTSMediaPlayerViewController alloc] initWithContentIdentifier:self.identifier dataSource:self.dataSource];
		UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
		if (rootViewController.presentedViewController) {
			[rootViewController dismissViewControllerAnimated:YES completion:^{
				[rootViewController presentViewController:mediaPlayerViewController animated:YES completion:nil];
			}];
		}
		else {
			[rootViewController presentViewController:mediaPlayerViewController animated:YES completion:nil];
		}
	}
	completionHandler(YES);
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
	if (!self.currentViewController) {
		[self reset];
	}
}

- (AVPictureInPictureController *)pictureInPictureController
{
    // Lazily installs itself as delegate, in case the PIP controller gets recreated
    AVPictureInPictureController *pictureInPictureController = super.pictureInPictureController;
    if (!pictureInPictureController.delegate) {
        pictureInPictureController.delegate = self;
    }
    return pictureInPictureController;
}

@end
