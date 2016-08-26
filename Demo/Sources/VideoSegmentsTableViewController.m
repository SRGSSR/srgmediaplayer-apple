//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
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
