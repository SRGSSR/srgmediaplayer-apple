//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "VideosTableViewController.h"

@implementation VideosTableViewController

- (NSString *) mediaURLPath
{
	return @"MediaURLs";
}

- (NSString *) mediaURLKey
{
	return @"Movies";
}

- (NSArray *) actionCellIdentifiers
{
	return @[ @"CellDefaultIOS",
			  @"CellDefaultRTS",
			  @"CellInline"];
}

@end
