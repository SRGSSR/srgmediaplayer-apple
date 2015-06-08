//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "MultiplayerViewController.h"

@implementation MultiplayerViewController

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
