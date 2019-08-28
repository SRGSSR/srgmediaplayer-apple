//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerNavigationController.h"

@implementation SRGMediaPlayerNavigationController

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.topViewController.preferredStatusBarStyle;
}

@end
