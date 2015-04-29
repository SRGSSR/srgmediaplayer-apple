//
//  Created by Samuel Défago on 29.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "DemoTimelineViewController.h"

@interface DemoTimelineViewController ()

@property (nonatomic) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet UIView *videoView;

@end

@implementation DemoTimelineViewController

#pragma mark - View lifecycle

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self.mediaPlayerController attachPlayerToView:self.videoView];
}

- (void) viewWillAppear:(BOOL)animated
{
	if ([self isMovingToParentViewController] || [self isBeingPresented])
 {
		[self.mediaPlayerController play];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if ([self isMovingFromParentViewController] || [self isBeingDismissed])
	{
		[self.mediaPlayerController reset];
	}
}

#pragma mark - RTSMediaPlayerControllerDataSource protocol

- (void)mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	NSURL *URL = [NSURL URLWithString:@"http://test.event.api.swisstxt.ch:80/v1/stream/srf/byEventItemIdAndType/265862/hls"];
	[[[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		if (error)
		{
			completionHandler(nil, error);
			return;
		}
		
		NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (! responseString)
		{
			NSError *responseError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
			completionHandler(nil, responseError);
		}
		responseString = [responseString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
		
		NSURL *URL = [NSURL URLWithString:responseString];
		completionHandler(URL, nil);
	}] resume];
}

#pragma mark - Actions

- (IBAction) dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
