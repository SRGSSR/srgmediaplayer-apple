//
//  CSRequest+RTSNotification.m
//  RTSMobileKit
//
//  Created by Cédric Luthi on 26.08.14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import "CSRequest+RTSAnalytics_private.h"
#import <objc/runtime.h>

NSString * const RTSAnalyticsComScoreRequestDidFinishNotification = @"RTSAnalyticsComScoreRequestDidFinish";
NSString * const RTSAnalyticsComScoreRequestSuccessUserInfoKey = @"RTSAnalyticsSuccess";
NSString * const RTSAnalyticsComScoreRequestLabelsUserInfoKey = @"RTSAnalyticsLabels";

static NSDictionary *RTSDictionaryFromURLEncodedStringWithEncoding(NSString *URLEncodedString, NSStringEncoding encoding)
{
    NSMutableDictionary *queryComponents = [NSMutableDictionary dictionary];
    for (NSString *keyValuePairString in [URLEncodedString componentsSeparatedByString:@"&"]) {
        NSArray *keyValuePairArray = [keyValuePairString componentsSeparatedByString:@"="];
        if ([keyValuePairArray count] < 2) continue; // Verify that there is at least one key, and at least one value.  Ignore extra = signs
        NSString *key = [[keyValuePairArray objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:encoding];
        NSString *value = [[keyValuePairArray objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:encoding];
        
            // URL spec says that multiple values are allowed per key
        id results = [queryComponents objectForKey:key];
        if (results) {
            if ([results isKindOfClass:[NSMutableArray class]]) {
                [(NSMutableArray *)results addObject:value];
            } else {
                    // On second occurrence of the key, convert into an array
                NSMutableArray *values = [NSMutableArray arrayWithObjects:results, value, nil];
                [queryComponents setObject:values forKey:key];
            }
        } else {
            [queryComponents setObject:value forKey:key];
        }
    }
    return queryComponents;
}

@implementation CSRequest (RTSNotification)

static BOOL (*sendIMP)(CSRequest *, SEL);

static BOOL NotificationSend(CSRequest *self, SEL _cmd);
static BOOL NotificationSend(CSRequest *self, SEL _cmd)
{
	BOOL success = sendIMP(self, _cmd);
	
	NSURLRequest *request = [self valueForKey:@"request"];
	NSDictionary *labels = RTSDictionaryFromURLEncodedStringWithEncoding(request.URL.query, NSUTF8StringEncoding);
	NSDictionary *userInfo = @{ RTSAnalyticsComScoreRequestSuccessUserInfoKey: @(success), RTSAnalyticsComScoreRequestLabelsUserInfoKey: labels };
	[[NSNotificationCenter defaultCenter] postNotificationName:RTSAnalyticsComScoreRequestDidFinishNotification object:request userInfo:userInfo];
	
	return success;
}

+ (void)load
{
	Method send = class_getInstanceMethod(self, @selector(send));
	sendIMP = (__typeof__(sendIMP))method_getImplementation(send);
	NSAssert(sendIMP, @"-[CSRequest send] implementation not found");
	method_setImplementation(send, (IMP)NotificationSend);
}

@end
