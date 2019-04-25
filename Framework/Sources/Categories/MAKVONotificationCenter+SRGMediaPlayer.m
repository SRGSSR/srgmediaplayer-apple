//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MAKVONotificationCenter+SRGMediaPlayer.h"

@implementation NSObject (MAKVONotificationCenter_SRGMediaPlayer)

- (id<MAKVOObservation>)srg_addMainThreadObserver:(id)observer
                                          keyPath:(id<MAKVOKeyPathSet>)keyPath
                                          options:(NSKeyValueObservingOptions)options
                                            block:(void (^)(MAKVONotification * _Nonnull))block
{
    return [self addObserver:observer keyPath:keyPath options:options block:^(MAKVONotification *notification) {
        if (NSThread.isMainThread) {
            block(notification);
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(notification);
            });
        }
    }];
}

@end
