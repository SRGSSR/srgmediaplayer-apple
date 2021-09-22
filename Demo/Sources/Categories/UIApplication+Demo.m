//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIApplication+Demo.h"

@implementation UIApplication (Demo)

- (UIWindow *)demo_mainWindow
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UIWindow * _Nullable window, NSDictionary<NSString *,id> * _Nullable bindings) {
        return window.keyWindow;
    }];
    return [self.windows filteredArrayUsingPredicate:predicate].firstObject;
}

@end
