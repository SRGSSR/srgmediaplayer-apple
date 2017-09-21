//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+MediaPlayerTests.h"

#import "NotificationListener.h"

#import <libextobjc/libextobjc.h>
#import <objc/runtime.h>

static void *s_notiticationListener = &s_notiticationListener;

@implementation XCTestCase (MediaPlayerTests)

- (XCTestExpectation *)mpt_expectationForNotification:(NSNotificationName)notificationName object:(id)objectToObserve handler:(XCNotificationExpectationHandler)handler
{
    NSString *description = [NSString stringWithFormat:@"Expectation for notification '%@' from object %@", notificationName, objectToObserve];
    XCTestExpectation *expectation = [self expectationWithDescription:description];
    
    __block NotificationListener *notificationListener = [[NotificationListener alloc] initWithNotificationName:notificationName object:objectToObserve handler:^(NSNotification * _Nonnull notification) {
        void (^fulfill)(void) = ^{
            [notificationListener stop];
            notificationListener = nil;
            
            objc_setAssociatedObject(expectation, s_notiticationListener, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [expectation fulfill];
        };
        
        if (handler) {
            if (handler(notification)) {
                fulfill();
            }
        }
        else {
            fulfill();
        }
    }];
    objc_setAssociatedObject(expectation, s_notiticationListener, notificationListener, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [notificationListener start];
    
    return expectation;
}

@end
