//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "VideoMultiplayerTableViewController.h"

@implementation VideoMultiplayerTableViewController

- (NSString *)mediaURLPath
{
	return @"MultiplayerURLs";
}

- (NSString *)mediaURLKey
{
	return @"Movies";
}

- (NSArray *)actionCellIdentifiers
{
	return @[ @"CellMultiPlayers" ];
}

@end
