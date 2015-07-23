//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "VideosTimeshiftTableViewController.h"

@implementation VideosTimeshiftTableViewController

- (NSString *)mediaURLPath
{
	return @"TimeshiftURLs";
}

- (NSString *)mediaURLKey
{
	return @"Movies";
}

- (NSArray *)actionCellIdentifiers
{
	return @[ @"CellDefaultIOS",
			  @"CellDefaultRTS",
			  @"CellTimeshift" ];
}

@end
