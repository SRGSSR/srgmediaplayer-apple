//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
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
