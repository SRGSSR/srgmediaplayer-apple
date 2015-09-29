//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemoTimelineConfigurationViewController.h"

#import "DemoTimelineViewController.h"

@interface DemoTimelineConfigurationViewController ()

@property (nonatomic, weak) IBOutlet UITextField *videoIdentifierTextField;

@end

@implementation DemoTimelineConfigurationViewController

#pragma mark - Segues

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"play"]) {
		NSAssert([segue.destinationViewController isKindOfClass:[DemoTimelineViewController class]], @"Expect DemoTimelineViewController");
		DemoTimelineViewController *demoTimelineViewController = segue.destinationViewController;
		demoTimelineViewController.videoIdentifier = self.videoIdentifierTextField.text;
	}
}

#pragma mark - UITextFieldDelegate protocol

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

@end
