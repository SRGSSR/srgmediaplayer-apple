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

- (IBAction) play:(id)sender
{
	[self.mediaPlayerController playIdentifier:self.mediaURL.absoluteString];
}

#pragma mark - RTSMediaPlayerControllerDataSource

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	completionHandler([NSURL URLWithString:identifier], nil);
}

@end
