//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A timer class, similar to `NSTimer`, but optionally pausing updates when the application is sent to the background,
 *  and requiring no run loop scheduling.
 */
@interface SRGTimer : NSObject

/**
 *  Convenience constructor.
 */
+ (SRGTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                            repeats:(BOOL)repeats
                         background:(BOOL)background
                              queue:(nullable dispatch_queue_t)queue
                              block:(void (^)(void))block;

/**
 *  Create a timer. After instantiation, call `-resume` to start the timer.
 *
 *  @param interval   The interval at which the block must be executed.
 *  @param repeats    Whether the timer repeats until invalidated.
 *  @param background If set to `YES`, the timer is allowed to continue when the application is sent to the background,
 *                    otherwise it is paused and resume when the application returns to the foreground.
 *  @param queue      The serial queue onto which block should be enqueued (main queue if `NULL`).
 *  @param block      The block to be executed.
 */
- (instancetype)initWithTimeInterval:(NSTimeInterval)interval
                             repeats:(BOOL)repeats
                          background:(BOOL)background
                               queue:(nullable dispatch_queue_t)queue
                               block:(void (^)(void))block NS_DESIGNATED_INITIALIZER;

/**
 *  Resume the timer.
 */
- (void)resume;

/**
 *  Fire the timer, without changing its scheduling. If the timer is non-repeating it will be invalidated afterwards.
 *
 *  @discussion The block is called in the queue provided at creation time.
 */
- (void)fire;

/**
 *  Suspend the timer.
 */
- (void)suspend;

/**
 *  Invalidate the timer (which cannot be used anymore afterwards).
 */
- (void)invalidate;

@end

@interface SRGTimer (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
