//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIApplication+SRGMediaPlayer.h"

@implementation UIApplication (SRGMediaPlayer)

- (UIWindow *)srgmediaplayer_mainWindow
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UIWindow * _Nullable window, NSDictionary<NSString *,id> * _Nullable bindings) {
        return window.keyWindow;
    }];
    return [self.windows filteredArrayUsingPredicate:predicate].firstObject;
}

@end
