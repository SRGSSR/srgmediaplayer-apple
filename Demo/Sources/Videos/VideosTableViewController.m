//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "VideosTableViewController.h"

@implementation VideosTableViewController

- (NSString *)title
{
    return @"Videos";
}

- (NSString *)mediaURLPath
{
    return @"MediaURLs";
}

- (NSString *)mediaURLKey
{
    return @"Movies";
}

- (NSArray *)actionCellIdentifiers
{
    return @[ @"iOSMediaPlayerCell",
              @"SRGMediaPlayerCell",
              @"InlineSRGMediaPlayerCell"];
}

@end
