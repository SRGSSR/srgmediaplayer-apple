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

- (id)mediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
    contentURLForIdentifier:(NSString *)identifier
          completionHandler:(void (^)(NSString *, NSURL *, NSError *))completionHandler
{
    completionHandler(identifier, self.mediaURL, nil);
    
    // No need for a connection handle, completion handlers are called immediately
    return nil;
}

- (void)cancelContentURLRequest:(id)request
{}

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
