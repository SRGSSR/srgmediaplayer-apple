//
//  Created by Frédéric Humbert-Droz on 10/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsTracker.h"
#import "RTSAnalyticsNetmetrixTracker_private.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

static NSString * const LoggerDomainAnalyticsNetmetrix = @"Netmetrix";
static NSString * const RTSAnalyticsNetmetrixRequestDidFinishFakeNotification = @"RTSAnalyticsNetmetrixRequestDidFinishFake";

NSString * const RTSAnalyticsNetmetrixWillSendRequestNotification = @"RTSAnalyticsNetmetrixWillSendRequest";
NSString * const RTSAnalyticsNetmetrixRequestDidFinishNotification = @"RTSAnalyticsNetmetrixRequestDidFinish";
NSString * const RTSAnalyticsNetmetrixRequestSuccessUserInfoKey = @"RTSAnalyticsNetmetrixSuccess";
NSString * const RTSAnalyticsNetmetrixRequestResponseUserInfoKey = @"RTSAnalyticsNetmetrixResponse";

@interface RTSAnalyticsNetmetrixTracker ()

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, assign) SSRBusinessUnit businessUnit;
@property (nonatomic, assign) BOOL production;

@end

@implementation RTSAnalyticsNetmetrixTracker

- (instancetype) initWithAppID:(NSString *)appID businessUnit:(SSRBusinessUnit)businessUnit production:(BOOL)production
{
	if (!(self = [super init]))
		return nil;
	
	_appID = appID;
	_businessUnit = businessUnit;
	_production = production;
	
	DDLogDebug(@"%@ initialization\nAppID: %@\nDomain: %@", LoggerDomainAnalyticsNetmetrix, appID, self.netmetrixDomain);

	return self;
}

- (NSString *) netmetrixDomain
{
	NSArray *netmetrixDomains = @[ @"srf", @"rts", @"rtsi", @"rtr", @"swissinf" ];
	return netmetrixDomains[self.businessUnit];
}

#pragma mark - Track View

- (void) trackView
{
	NSString *netmetrixURLString = [NSString stringWithFormat:@"http://%@.wemfbox.ch/cgi-bin/ivw/CP/apps/%@/ios/%@", self.netmetrixDomain, self.appID, self.device];
	NSURL *netmetrixURL = [NSURL URLWithString:netmetrixURLString];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:netmetrixURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
	[request setHTTPMethod: @"GET"];
	[request setValue:@"image/gif" forHTTPHeaderField:@"Accept"];
	
	// Which User-Agent MUST be used is defined on http://www.net-metrix.ch/fr/produits/net-metrix-mobile/reglement/directives
	NSString *systemVersion = [[[UIDevice currentDevice] systemVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"];
	NSString *userAgent = [NSString stringWithFormat:@"Mozilla/5.0 (iOS-%@; CPU %@ %@ like Mac OS X)", self.device, self.operatingSystem, systemVersion];
	[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
	
	BOOL testMode = [self.appID isEqualToString:@"test"] || NSClassFromString(@"XCTestCase") != NULL;
	if (self.production || testMode)
	{
		DDLogVerbose(@"%@ : will send view event:\nurl        = %@\nuser-agent = %@", LoggerDomainAnalyticsNetmetrix, netmetrixURLString, userAgent);
		[[NSNotificationCenter defaultCenter] postNotificationName:RTSAnalyticsNetmetrixWillSendRequestNotification object:request userInfo:nil];
	}
	
	if (testMode)
	{
		DDLogWarn(@"%@ response will be fake due to testing flag or xctest bundle presence", LoggerDomainAnalyticsNetmetrix);
		[[NSNotificationCenter defaultCenter] postNotificationName:RTSAnalyticsNetmetrixRequestDidFinishFakeNotification object:request userInfo:nil];
	}
	else if (self.production)
	{
		[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
			
			BOOL succes = !connectionError;
			if (succes) {
				DDLogInfo(@"%@ view > %@", LoggerDomainAnalyticsNetmetrix, request.HTTPMethod);
			}else{
				DDLogError(@"%@ ERROR sending %@ view : %@", LoggerDomainAnalyticsNetmetrix, request.HTTPMethod, connectionError.localizedDescription);
			}
			
			DDLogDebug(@"%@ view event sent:\n%@", LoggerDomainAnalyticsNetmetrix, [(NSHTTPURLResponse *)response allHeaderFields]);
			
			NSMutableDictionary *userInfo = [@{ RTSAnalyticsNetmetrixRequestSuccessUserInfoKey: @(succes) } mutableCopy];
			if (response)
				userInfo[RTSAnalyticsNetmetrixRequestResponseUserInfoKey] = response;
			
			[[NSNotificationCenter defaultCenter] postNotificationName:RTSAnalyticsNetmetrixRequestDidFinishNotification object:request userInfo:[userInfo copy]];
		}];
	}
}

#pragma mark - Helpers


- (NSString *)device
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		return @"phone";
	}
	else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		return @"tablet";
	}
	else
	{
		return @"universal";
	}
}

- (NSString *)operatingSystem
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		return @"iPhone OS";
	}
	else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		return @"iPad OS";
	}
	else
	{
		return @"OS";
	}
}

@end
