//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerSharedController.h"

#import "RTSMediaPlayerViewController.h"

@implementation RTSMediaPlayerSharedController

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
	// RTSMediaPlayerViewController is always displayed modally, the following therefore always works
	UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
	[rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
	// If no RTSMediaPlayerViewController instance is currently displayed (always modally)
	if (![rootViewController.presentedViewController isKindOfClass:[RTSMediaPlayerViewController class]]) {
		RTSMediaPlayerViewController *mediaPlayerViewController = [[RTSMediaPlayerViewController alloc] initWithContentIdentifier:self.identifier dataSource:self.dataSource];
		
		
		// Dismiss any modal currently displayed if needed
		if (rootViewController.presentedViewController) {
			[rootViewController dismissViewControllerAnimated:YES completion:^{
				[rootViewController presentViewController:mediaPlayerViewController animated:YES completion:^{
					// It is very important that this block is called at the very end of the process, otherwise silly
					// things might happen during the transition (e.g. player rate set to 0)
					completionHandler(YES);
				}];
			}];
		}
		else {
			[rootViewController presentViewController:mediaPlayerViewController animated:YES completion:^{
				// See comment above
				completionHandler(YES);
			}];
		}
	}
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
	// Reset the status of the player when picture in picture is exited anywhere except from the RTSMediaPlayerViewController
	// itself
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
	if (![rootViewController.presentedViewController isKindOfClass:[RTSMediaPlayerViewController class]]) {
		[self reset];
	}
}

- (AVPictureInPictureController *)pictureInPictureController
{
	// Lazily installs itself as delegate, in case the pictue in picture controller gets recreated
	AVPictureInPictureController *pictureInPictureController = super.pictureInPictureController;
	if (!pictureInPictureController.delegate) {
		pictureInPictureController.delegate = self;
	}
	return pictureInPictureController;
}

@end
