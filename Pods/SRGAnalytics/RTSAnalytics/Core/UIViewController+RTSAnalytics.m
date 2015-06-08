//
//  UIViewController+Analytics.m
//  RTSAnalytics
//
//  Created by Frédéric Humbert-Droz on 09/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "UIViewController+RTSAnalytics.h"

#import <objc/runtime.h>

#import "RTSAnalyticsTracker.h"
#import "NSString+RTSAnalytics.h"
#import "RTSAnalyticsPageViewDataSource.h"

@implementation UIViewController (RTSAnalytics)

static void (*viewDidAppearIMP)(UIViewController *, SEL, BOOL);
static void AnalyticsViewDidAppear(UIViewController *self, SEL _cmd, BOOL animated);
static void AnalyticsViewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{
	viewDidAppearIMP(self, _cmd, animated);
	[self trackPageView];
}

- (void)trackPageView
{
	id<RTSAnalyticsPageViewDataSource> viewEventDataSource = nil;
    if ([self conformsToProtocol:@protocol(RTSAnalyticsPageViewDataSource)]) {
		viewEventDataSource = (id<RTSAnalyticsPageViewDataSource>)self;
    }
	
	[[RTSAnalyticsTracker sharedTracker] trackPageViewForDataSource:viewEventDataSource];
}

+ (void)load
{
	Method viewDidAppear = class_getInstanceMethod(self, @selector(viewDidAppear:));
	viewDidAppearIMP = (__typeof__(viewDidAppearIMP))method_getImplementation(viewDidAppear);
	method_setImplementation(viewDidAppear, (IMP)AnalyticsViewDidAppear);
}

@end
