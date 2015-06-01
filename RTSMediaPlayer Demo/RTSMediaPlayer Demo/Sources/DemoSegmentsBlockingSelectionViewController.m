//
//  DemoSegmentsBlockingSelectionViewController.m
//  RTSMediaPlayer Demo
//
//  Created by Cédric Foellmi on 01/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <libextobjc/EXTScope.h>
#import "DemoSegmentsBlockingSelectionViewController.h"
#import "DemoSegmentsBlockingViewController.h"
#import "SegmentCollectionViewCell.h"
#import "PseudoILDataProvider.h"

@interface DemoSegmentsBlockingSelectionViewController ()

@end

@implementation DemoSegmentsBlockingSelectionViewController

#pragma mark - Segues

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"play"]) {
		NSAssert([segue.destinationViewController isKindOfClass:[DemoSegmentsBlockingViewController class]], @"Expect DemoSegmentsBlockingViewController");
		DemoSegmentsBlockingViewController *demoViewController = segue.destinationViewController;
		
		NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
		if (indexPath.row == 0) {
			demoViewController.videoIdentifier = @"srf-0";
		}
		
	}
}

@end
