//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SceneDelegate.h"

#import "Application.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
    if ([scene isKindOfClass:UIWindowScene.class]) {
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
        [self.window makeKeyAndVisible];
        self.window.rootViewController = ApplicationRootViewController();
    }
}

@end
