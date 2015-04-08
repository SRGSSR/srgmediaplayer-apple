//
//  Created by Cédric Luthi on 27.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "DemoInlineViewController.h"

@implementation DemoInlineViewController

- (void) viewDidLoad
{
	[super viewDidLoad];
	[self.mediaPlayerController attachPlayerToView:self.videoContainerView];
}

#pragma mark - RTSMediaPlayerControllerDataSource

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	completionHandler(self.mediaURL, nil);
}

- (IBAction) prepareToPlay:(id)sender
{
	[self.mediaPlayerController prepareToPlay];
}

- (IBAction) play:(id)sender
{
	[self.mediaPlayerController.player play];
}

@end
