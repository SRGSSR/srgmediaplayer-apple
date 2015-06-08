//
// CSTaskExecutor.h
//
// Copyright 2014 comScore, Inc. All right reserved.
//
#import "CSCore.h"
/** Class implementing a task executor. All tasks will be
 * executed sequentially in the background */
@interface CSTaskExecutor : NSObject {
    dispatch_queue_t _queue;
    CSCore* _core;
}

/** Initializes the instance using gcd if available */
- (id)initWithCore:(CSCore *)core;

/** Executes the block immediately or if background was selected
 *  then it's added to the background task queue to be executed */
- (void)execute:(dispatch_block_t)block background:(BOOL)background;

/** Executes the block after the provided delay on the main thread or
* if background was selected then it's executed on the background task queue */
- (void)execute:(dispatch_block_t)block background:(BOOL)background delay:(double)delay;

/**
* Configures a timer to run at specified interval after a specified delay.
* When the timer tick event is fired, the specified selector on the specified target
* will be invoked.
*
* This method returns a unique timer ID.
*/
- (NSString *)startTimerWithInterval:(double)interval
                               delay:(double)delay
                              target:(id)target
                            selector:(SEL)selector
                            userInfo:(id)userInfo
                             repeats:(BOOL)repeats
            invokeSelectorAfterDelay:(BOOL)invokeSelectorAfterDelay;

/**
* Cancels the timer with the specified timer ID.
*/
- (void)cancelTimerWithId:(NSString *)timerId;

/** Blocks the thread until all previous tasks are finished
 *
 *  WARNING, THIS CALL WILL BLOCK THE THREAD!!!!
 *
 *  Use with caution.
 */
- (void)waitForTasks;

@end
