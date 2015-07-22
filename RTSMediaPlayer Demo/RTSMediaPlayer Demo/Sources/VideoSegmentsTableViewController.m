//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "VideoSegmentsTableViewController.h"
#import "VideoSegmentsPlayerViewController.h"
#import "PseudoILDataProvider.h"

@implementation VideoSegmentsTableViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSAssert([segue.destinationViewController isKindOfClass:[VideoSegmentsPlayerViewController class]],
			 @"Expect VideoSegmentsPlayerViewController");
	
	NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
	VideoSegmentsPlayerViewController *demoViewController = segue.destinationViewController;
	demoViewController.videoIdentifier = [NSString stringWithFormat:@"%@", @(indexPath.row)];
}

@end
