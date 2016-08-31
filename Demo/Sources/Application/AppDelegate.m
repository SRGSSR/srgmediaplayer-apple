//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "VideosTableViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

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

@interface LogFormatter : NSObject <DDLogFormatter>
@end

@implementation LogFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"HH:mm:ss.SSS";
    });
    return [NSString stringWithFormat:@"%@ [%@] %@", [dateFormatter stringFromDate:logMessage.timestamp], logMessage.threadID, logMessage.message];
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    ttyLogger.colorsEnabled = YES;
    ttyLogger.logFormatter = [LogFormatter new];
    [DDLog addLogger:ttyLogger withLevel:DDLogLevelInfo];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    VideosTableViewController *videosTableViewController = [[VideosTableViewController alloc] init];
    videosTableViewController.tabBarItem.image = [UIImage imageNamed:@"videos"];
    UINavigationController *videosNavigationController = [[UINavigationController alloc] initWithRootViewController:videosTableViewController];
    
    tabBarController.viewControllers = @[videosNavigationController];
    self.window.rootViewController = tabBarController;
    
    // Avoid applying tint color to tab bar images
    [tabBarController.viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
        UITabBarItem *tabBarItem = viewController.tabBarItem;
        tabBarItem.image = [tabBarItem.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem.selectedImage = [tabBarItem.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }];
    
    
    
    
    
    
#if 0
    UIImage *moviesIcon = [UIImage imageNamed:@"videos"];
    UIImage *segmentsIcon = [UIImage imageNamed:@"segments"];
    UIImage *multiplayerIcon = [UIImage imageNamed:@"screen"];
    UIImage *audiosIcon = [UIImage imageNamed:@"audios"];

    NSArray<UIImage *> *images = @[moviesIcon, segmentsIcon, multiplayerIcon, moviesIcon, audiosIcon];

    [tabBarController.tabBar.items enumerateObjectsUsingBlock:^(UITabBarItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        item.image = [images[idx] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        item.selectedImage = [images[idx] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }];
#endif

    return YES;
}

@end
