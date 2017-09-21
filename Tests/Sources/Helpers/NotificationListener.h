//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Simple notification listener.
 */
@interface NotificationListener : NSObject

/**
 *  Create a listener for a notification and object, calling the specified handler when the notification is received.
 */
- (instancetype)initWithNotificationName:(NSNotificationName)notificationName object:(nullable id)object handler:(void (^)(NSNotification *notification))handler;

/**
 *  Start listening to notifications.
 */
- (void)start;

/**
 *  Stop listening to notifications.
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
