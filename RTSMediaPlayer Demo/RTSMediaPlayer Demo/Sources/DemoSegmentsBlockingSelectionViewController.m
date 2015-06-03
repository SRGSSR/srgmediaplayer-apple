//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "DemoSegmentsBlockingSelectionViewController.h"
#import "DemoSegmentsBlockingViewController.h"
#import "PseudoILDataProvider.h"

@implementation DemoSegmentsBlockingSelectionViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSAssert([segue.destinationViewController isKindOfClass:[DemoSegmentsBlockingViewController class]],
			 @"Expect DemoSegmentsBlockingViewController");
	
	NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
	DemoSegmentsBlockingViewController *demoViewController = segue.destinationViewController;
	demoViewController.videoIdentifier = [NSString stringWithFormat:@"%@", @(indexPath.row)];
}

@end
