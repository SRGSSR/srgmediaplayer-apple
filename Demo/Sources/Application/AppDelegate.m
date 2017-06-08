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
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    MediasViewController *videosViewController = [[MediasViewController alloc] initWithMediaFileName:@"MediaURLs"];
    videosViewController.title = DemoNonLocalizedString(@"Videos");
    videosViewController.tabBarItem.image = [UIImage imageNamed:@"videos"];
    UINavigationController *videosNavigationController = [[UINavigationController alloc] initWithRootViewController:videosViewController];
    
    MediasViewController *segmentsViewController = [[MediasViewController alloc] initWithMediaFileName:@"SegmentURLs"];
    segmentsViewController.title = DemoNonLocalizedString(@"Segments");
    segmentsViewController.tabBarItem.image = [UIImage imageNamed:@"screen"];
    UINavigationController *segmentsNavigationController = [[UINavigationController alloc] initWithRootViewController:segmentsViewController];
    
    MediasViewController *multiVideosViewController = [[MediasViewController alloc] initWithMediaFileName:@"MultiplayerURLs"];
    multiVideosViewController.title = DemoNonLocalizedString(@"Multi-stream");
    multiVideosViewController.tabBarItem.image = [UIImage imageNamed:@"screen"];
    UINavigationController *multiVideosNavigationController = [[UINavigationController alloc] initWithRootViewController:multiVideosViewController];
    
    MediasViewController *timeshiftViewController = [[MediasViewController alloc] initWithMediaFileName:@"TimeshiftURLs"];
    timeshiftViewController.title = DemoNonLocalizedString(@"Timeshift");
    timeshiftViewController.tabBarItem.image = [UIImage imageNamed:@"videos"];
    UINavigationController *timeshiftNavigationController = [[UINavigationController alloc] initWithRootViewController:timeshiftViewController];
    
    MediasViewController *audiosViewController = [[MediasViewController alloc] initWithMediaFileName:@"AudioURLs"];
    audiosViewController.title = DemoNonLocalizedString(@"Audios");
    audiosViewController.tabBarItem.image = [UIImage imageNamed:@"audios"];
    UINavigationController *audiosNavigationController = [[UINavigationController alloc] initWithRootViewController:audiosViewController];
    
    tabBarController.viewControllers = @[videosNavigationController, segmentsNavigationController, multiVideosNavigationController, timeshiftNavigationController, audiosNavigationController];
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
