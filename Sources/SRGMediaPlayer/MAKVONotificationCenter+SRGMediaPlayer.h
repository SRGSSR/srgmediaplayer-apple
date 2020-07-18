//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import MAKVONotificationCenter;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (MAKVONotificationCenter_SRGMediaPlayer)

/**
 *  Same as -addObserver:keyPath:options:block:, but with guaranteed execution of the associated block on the main
 *  thread.
 */
- (id<MAKVOObservation>)srg_addMainThreadObserver:(id)observer
                                          keyPath:(id<MAKVOKeyPathSet>)keyPath
                                          options:(NSKeyValueObservingOptions)options
                                            block:(void (^)(MAKVONotification *notification))block;

@end

NS_ASSUME_NONNULL_END
