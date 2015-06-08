//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "DemoSegmentsSelectionViewController.h"
#import "DemoSegmentsViewController.h"
#import "PseudoILDataProvider.h"

@implementation DemoSegmentsSelectionViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSAssert([segue.destinationViewController isKindOfClass:[DemoSegmentsViewController class]],
			 @"Expect DemoSegmentsViewController");
	
	NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
	DemoSegmentsViewController *demoViewController = segue.destinationViewController;
	demoViewController.videoIdentifier = [NSString stringWithFormat:@"%@", @(indexPath.row)];
}

@end
