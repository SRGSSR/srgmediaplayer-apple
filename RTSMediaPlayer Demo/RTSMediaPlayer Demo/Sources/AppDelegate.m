//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "AppDelegate.h"

#import <CocoaLumberjack/CocoaLumberjack.h>


@interface LogFormatter : NSObject <DDLogFormatter>
@end

@implementation LogFormatter

- (NSString *) formatLogMessage:(DDLogMessage *)logMessage
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

@synthesize window = _window;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
	ttyLogger.colorsEnabled = YES;
	ttyLogger.logFormatter = [LogFormatter new];
	[DDLog addLogger:ttyLogger withLevel:DDLogLevelInfo];
	
	
	UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
	
	UIImage *moviesIcon = [UIImage imageNamed:@"videos"];
	UIImage *segmentsIcon = [UIImage imageNamed:@"segments"];
	UIImage *multiplayerIcon = [UIImage imageNamed:@"screen"];
	UIImage *audiosIcon = [UIImage imageNamed:@"audios"];
	
	NSArray *images = @[moviesIcon, segmentsIcon, multiplayerIcon, audiosIcon];
	
	[tabBarController.tabBar.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		UITabBarItem *item = (UITabBarItem *)obj;
		item.image = [images[idx] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
	}];

	
	return YES;
}

@end
