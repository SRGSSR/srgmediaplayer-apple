//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "MediasViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <SRGLogger/SRGLogger.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.window makeKeyAndVisible];
    
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    MediasViewController *videosViewController = [[MediasViewController alloc] initWithTitle:NSLocalizedString(@"Videos", nil) configurationFileName:@"VideoDemoConfiguration" mediaPlayerType:MediaPlayerTypeStandard];
    MediasViewController *segmentsViewController = [[MediasViewController alloc] initWithTitle:NSLocalizedString(@"Segments", nil) configurationFileName:@"SegmentDemoConfiguration" mediaPlayerType:MediaPlayerTypeSegments];
    MediasViewController *audiosViewController = [[MediasViewController alloc] initWithTitle:NSLocalizedString(@"Audios", nil) configurationFileName:@"AudioDemoConfiguration" mediaPlayerType:MediaPlayerTypeStandard];
    
#if TARGET_OS_IOS
    UINavigationController *videosNavigationController = [[UINavigationController alloc] initWithRootViewController:videosViewController];
    videosNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Videos", nil) image:[UIImage imageNamed:@"videos"] tag:0];
    
    UINavigationController *segmentsNavigationController = [[UINavigationController alloc] initWithRootViewController:segmentsViewController];
    segmentsNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Segments", nil) image:[UIImage imageNamed:@"segments"] tag:1];
    
    MediasViewController *multiPlayerViewController = [[MediasViewController alloc] initWithTitle:NSLocalizedString(@"Multi-stream", nil) configurationFileName:@"MultiPlayerDemoConfiguration" mediaPlayerType:MediaPlayerTypeMulti];
    UINavigationController *multiPlayerNavigationController = [[UINavigationController alloc] initWithRootViewController:multiPlayerViewController];
    multiPlayerNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Multi-stream", nil) image:[UIImage imageNamed:@"multiplayer"] tag:2];
    
    UINavigationController *audiosNavigationController = [[UINavigationController alloc] initWithRootViewController:audiosViewController];
    audiosNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Audios", nil) image:[UIImage imageNamed:@"audios"] tag:3];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[ videosNavigationController, segmentsNavigationController, multiPlayerNavigationController, audiosNavigationController ];
    self.window.rootViewController = tabBarController;
#else
    videosViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Videos", nil) image:nil tag:0];
    segmentsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Segments", nil) image:nil tag:1];
    audiosViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Audios", nil) image:nil tag:2];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[ videosViewController, segmentsViewController, audiosViewController ];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:tabBarController];
    self.window.rootViewController = navigationController;
#endif
    
    return YES;
}

@end
