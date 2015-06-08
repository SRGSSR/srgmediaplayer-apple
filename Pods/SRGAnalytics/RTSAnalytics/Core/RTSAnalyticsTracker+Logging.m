//
//  Created by Frédéric Humbert-Droz on 08/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsTracker+Logging.h"

#import <comScore-iOS-SDK-RTS/CSCore.h>
#import <comScore-iOS-SDK-RTS/CSComScore.h>
#import <comScore-iOS-SDK-RTS/CSTaskExecutor.h>

#import "CSRequest+RTSAnalytics_private.h"

#import <CocoaLumberjack/CocoaLumberjack.h>

static BOOL isLogEnabled = NO;

@implementation RTSAnalyticsTracker (Logging)

- (void)setLogEnabled:(BOOL)enabled
{
	isLogEnabled = enabled;
	
	if (isLogEnabled) {
		[self startLoggingInternalComScoreTasks];
	}
    else {
		[self stopLoggingInternalComScoreTasks];
	}
}

- (void)startLoggingInternalComScoreTasks
{
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(comScoreRequestDidFinish:)
                                                 name:RTSAnalyticsComScoreRequestDidFinishNotification
                                               object:nil];
	
    // +[CSComScore setPixelURL:] is dispatched on an internal comScore queue, so calling +[CSComScore pixelURL]
    // right after doesn’t work, we must also dispatch it on the same queue!
	[[[CSComScore core] taskExecutor] execute:^
	 {
		 const SEL selectors[] = {
			 @selector(appName),
			 @selector(pixelURL),
			 @selector(publisherSecret),
			 @selector(customerC2),
			 @selector(version),
			 @selector(labels)
		 };
		 
		 NSMutableString *message = [NSMutableString new];
		 for (NSUInteger i = 0; i < sizeof(selectors) / sizeof(selectors[0]); i++) {
			 SEL selector = selectors[i];
			 [message appendFormat:@"%@: %@\n", NSStringFromSelector(selector), [CSComScore performSelector:selector]];
		 }
		 [message deleteCharactersInRange:NSMakeRange(message.length - 1, 1)];
		 DDLogDebug(@"%@", message);
		 
	 } background:YES];
}

- (void)stopLoggingInternalComScoreTasks
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:RTSAnalyticsComScoreRequestDidFinishNotification object:nil];
}

#pragma mark - Notifications

- (void)comScoreRequestDidFinish:(NSNotification *)notification
{
	NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
	NSUInteger maxKeyLength = [[[labels allKeys] valueForKeyPath:@"@max.length"] unsignedIntegerValue];
	
	NSMutableString *dictionaryRepresentation = [NSMutableString new];
	for (NSString *key in [[labels allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		[dictionaryRepresentation appendFormat:@"%@ = %@\n", [key stringByPaddingToLength:maxKeyLength withString:@" " startingAtIndex:0], labels[key]];
	}
	
	NSString *ns_st_ev = labels[@"ns_st_ev"];
	NSString *ns_ap_ev = labels[@"ns_ap_ev"];
	NSString *type = labels[@"ns_st_ty"];
	NSString *typeSymbol = @"\U00002753"; // BLACK QUESTION MARK ORNAMENT
	
	if ([type.lowercaseString isEqual:@"audio"]) {
		typeSymbol = @"\U0001F4FB"; // RADIO
	}
	else if ([type.lowercaseString isEqual:@"video"]) {
		typeSymbol = @"\U0001F4FA"; // TELEVISION
	}
	
	if ([labels[@"ns_st_li"] boolValue]) {
		typeSymbol = [typeSymbol stringByAppendingString:@"\U0001F6A8"];
	}
	
	NSString *event = ns_st_ev ?  [typeSymbol stringByAppendingFormat:@" %@", ns_st_ev] : ns_ap_ev;
	NSString *name = ns_st_ev ? [NSString stringWithFormat:@"%@ / %@", labels[@"ns_st_pl"], labels[@"ns_st_ep"]] : labels[@"name"];
	
	BOOL success = [notification.userInfo[RTSAnalyticsComScoreRequestSuccessUserInfoKey] boolValue];
	if (success) {
		DDLogInfo(@"%@ > %@", event, name);
	}
	else {
		DDLogError(@"ERROR sending %@ > %@", event, name);
	}
	
	DDLogDebug(@"Comscore view event sent:\n%@", dictionaryRepresentation);
}

@end
