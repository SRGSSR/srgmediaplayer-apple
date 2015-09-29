//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AudiosTableViewController.h"

@implementation AudiosTableViewController

- (NSString *) mediaURLPath
{
	return @"AudioURLs";
}

- (NSString *) mediaURLKey
{
	return @"Audios";
}

- (NSArray *) actionCellIdentifiers
{
	return @[ @"CellDefaultIOS",
			  @"CellDefaultRTS" ];
}

@end
