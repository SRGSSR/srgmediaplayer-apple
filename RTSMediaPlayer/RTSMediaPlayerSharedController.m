//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerSharedController.h"

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
	NSLog(@"---> Restore");
	completionHandler(YES);
}

@end
