//
//  Created by Cédric Luthi on 26.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
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
	[DDLog addLogger:ttyLogger];
	return YES;
}

@end
