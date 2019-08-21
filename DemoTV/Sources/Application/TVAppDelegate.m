//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TVAppDelegate.h"

#import "TVMediasViewController.h"

@interface TVAppDelegate ()

@end

@implementation TVAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.window makeKeyAndVisible];
    
    TVMediasViewController *videosViewController = [[TVMediasViewController alloc] initWithConfigurationFileName:@"VideoDemoConfiguration"];
    videosViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Videos", nil) image:nil tag:0];
    
    TVMediasViewController *segmentsViewController = [[TVMediasViewController alloc] initWithConfigurationFileName:@"SegmentDemoConfiguration"];
    segmentsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Segments", nil) image:nil tag:1];
    
    TVMediasViewController *audiosViewController = [[TVMediasViewController alloc] initWithConfigurationFileName:@"AudioDemoConfiguration"];
    audiosViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Audios", nil) image:nil tag:2];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[ videosViewController, segmentsViewController, audiosViewController ];
    self.window.rootViewController = tabBarController;
    
    return YES;
}

@end
