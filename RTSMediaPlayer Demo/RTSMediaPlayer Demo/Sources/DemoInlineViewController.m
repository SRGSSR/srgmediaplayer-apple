//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemoInlineViewController.h"

@implementation DemoInlineViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self.mediaPlayerController attachPlayerToView:self.videoContainerView];
}

#pragma mark - RTSMediaPlayerControllerDataSource

- (void)mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
	  contentURLForIdentifier:(NSString *)identifier
			completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	completionHandler(self.mediaURL, nil);
}

#pragma mark - UIViewController

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if ([self isMovingFromParentViewController]) {
		[self.mediaPlayerController reset];
	}
}

#pragma mark - Actions

- (IBAction)prepareToPlay:(id)sender
{
	[self.mediaPlayerController prepareToPlay];
}

- (IBAction)play:(id)sender
{
	[self.mediaPlayerController play];
}

- (IBAction)pause:(id)sender
{
	[self.mediaPlayerController pause];
}

- (IBAction)reset:(id)sender
{
	[self.mediaPlayerController reset];
}

@end
