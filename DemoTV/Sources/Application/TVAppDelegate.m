//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TVAppDelegate.h"

#import "TVMediasViewController.h"
#import "TVPlayersViewController.h"

@interface TVAppDelegate ()

@end

@implementation TVAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.window makeKeyAndVisible];
    
    TVPlayersViewController *playersViewController = [[TVPlayersViewController alloc] init];
    TVMediasViewController *demosViewController = [[TVMediasViewController alloc] init];
    
    UISplitViewController *splitViewController = [[UISplitViewController alloc] init];
    splitViewController.viewControllers = @[ playersViewController, demosViewController ];
    
    self.window.rootViewController = splitViewController;
    
    return YES;
}

@end
