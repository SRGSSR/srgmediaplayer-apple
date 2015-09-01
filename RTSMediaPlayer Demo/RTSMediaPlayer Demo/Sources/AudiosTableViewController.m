//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
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
