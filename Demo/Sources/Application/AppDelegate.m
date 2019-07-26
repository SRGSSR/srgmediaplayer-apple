//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "MediasViewController.h"
#import "NSBundle+Demo.h"

#import <AVFoundation/AVFoundation.h>
#import <SRGLogger/SRGLogger.h>

@interface UIImage (Tinting)

- (UIImage *)tintedImageWithColor:(UIColor *)color;

@end

@implementation UIImage (Tinting)

- (UIImage *)tintedImageWithColor:(UIColor *)color
{
    if (! color) {
        return self;
    }
    
    CGRect rect = CGRectMake(0.f, 0.f, self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0.f, self.size.height);
    CGContextScaleCTM(context, 1.0f, -1.f);
    
    CGContextDrawImage(context, rect, self.CGImage);
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.blackColor;
    [self.window makeKeyAndVisible];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    MediasViewController *videosViewController = [[MediasViewController alloc] initWithTitle:DemoNonLocalizedString(@"Videos") configurationFileName:@"VideoDemoConfiguration" mediaPlayerType:MediaPlayerTypeStandard];
    UINavigationController *videosNavigationController = [[UINavigationController alloc] initWithRootViewController:videosViewController];
    videosNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:DemoNonLocalizedString(@"Videos") image:[UIImage imageNamed:@"videos"] tag:0];
    
    MediasViewController *segmentsViewController = [[MediasViewController alloc] initWithTitle:DemoNonLocalizedString(@"Segments") configurationFileName:@"SegmentDemoConfiguration" mediaPlayerType:MediaPlayerTypeSegments];
    UINavigationController *segmentsNavigationController = [[UINavigationController alloc] initWithRootViewController:segmentsViewController];
    segmentsNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:DemoNonLocalizedString(@"Segments") image:[UIImage imageNamed:@"segments"] tag:1];
    
    MediasViewController *multiPlayerViewController = [[MediasViewController alloc] initWithTitle:DemoNonLocalizedString(@"Multi-stream") configurationFileName:@"MultiPlayerDemoConfiguration" mediaPlayerType:MediaPlayerTypeMulti];
    UINavigationController *multiPlayerNavigationController = [[UINavigationController alloc] initWithRootViewController:multiPlayerViewController];
    multiPlayerNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:DemoNonLocalizedString(@"Multi-stream") image:[UIImage imageNamed:@"multiplayer"] tag:2];
    
    MediasViewController *audiosViewController = [[MediasViewController alloc] initWithTitle:DemoNonLocalizedString(@"Audios") configurationFileName:@"AudioDemoConfiguration" mediaPlayerType:MediaPlayerTypeStandard];
    UINavigationController *audiosNavigationController = [[UINavigationController alloc] initWithRootViewController:audiosViewController];
    audiosNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:DemoNonLocalizedString(@"Audios") image:[UIImage imageNamed:@"audios"] tag:3];
    
    tabBarController.viewControllers = @[videosNavigationController, segmentsNavigationController, multiPlayerNavigationController, audiosNavigationController];
    self.window.rootViewController = tabBarController;
    
    // Avoid applying tint color to tab bar images
    [tabBarController.viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
        UITabBarItem *tabBarItem = viewController.tabBarItem;
        tabBarItem.image = [tabBarItem.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem.selectedImage = [tabBarItem.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }];
    
    return YES;
}

@end
