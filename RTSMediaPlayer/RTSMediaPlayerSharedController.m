//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerSharedController.h"

#import "RTSMediaPlayerViewController.h"

@implementation RTSMediaPlayerSharedController

- (instancetype)initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	if (self = [super initWithContentIdentifier:identifier dataSource:dataSource]) {
		self.pictureInPictureController.delegate = self;
	}
	return self;
}

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

@end
