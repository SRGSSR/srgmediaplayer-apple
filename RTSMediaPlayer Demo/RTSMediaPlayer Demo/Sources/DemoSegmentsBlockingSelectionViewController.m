//
//  DemoSegmentsBlockingSelectionViewController.m
//  RTSMediaPlayer Demo
//
//  Created by Cédric Foellmi on 01/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
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
