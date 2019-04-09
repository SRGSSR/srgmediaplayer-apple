//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Helper class used as target for a timer.
 */
// TODO: Remove when iOS 10 is the minimum required version
@interface SRGMediaPlayerTimerTarget : NSObject

/**
 *  Create the target with the specified to be executed when `-fire:` is called.
 */
- (instancetype)initWithBlock:(nullable void (^)(NSTimer *timer))block;

/**
 *  Execute the attached block on behalf of the specified timer.
 */
- (void)fire:(NSTimer *)timer;

@end

NS_ASSUME_NONNULL_END
