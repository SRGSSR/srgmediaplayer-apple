//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIWindow+Demo.h"

@implementation UIWindow (Demo)

- (UIViewController *)demo_topViewController
{
    UIViewController *topViewController = self.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

@end
