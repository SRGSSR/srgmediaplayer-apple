//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
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
