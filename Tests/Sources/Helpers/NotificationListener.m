//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NotificationListener.h"

@interface NotificationListener ()

@property (nonatomic, copy) NSNotificationName notificationName;
@property (nonatomic) id object;
@property (nonatomic, copy) void (^handler)(NSNotification *);

@end

@implementation NotificationListener

#pragma mark Object lifecycle

- (instancetype)initWithNotificationName:(NSNotificationName)notificationName object:(id)object handler:(void (^)(NSNotification * _Nonnull))handler
{
    if (self = [super init]) {
        self.notificationName = notificationName;
        self.object = object;
        self.handler = handler;
    }
    return self;
}

#pragma mark Helpers

- (void)start
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveNotification:)
                                                 name:self.notificationName
                                               object:self.object];

}

- (void)stop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:self.notificationName
                                                  object:self.object];
}

#pragma mark Notifications

- (void)didReceiveNotification:(NSNotification *)notification
{
    self.handler(notification);
}

@end
