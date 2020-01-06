//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGTimer.h"

#import <libextobjc/libextobjc.h>
#import <UIKit/UIKit.h>

@interface SRGTimer ()

@property (nonatomic) NSTimeInterval interval;
@property (nonatomic) BOOL repeats;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, copy) void (^block)(void);

@property (nonatomic) dispatch_source_t source;
@property (nonatomic, getter=isResumed) BOOL resumed;

@end

@implementation SRGTimer

#pragma mark Class methods

+ (SRGTimer *)timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats queue:(dispatch_queue_t)queue block:(void (^)(void))block
{
    return [[SRGTimer alloc] initWithTimeInterval:interval repeats:repeats queue:queue block:block];
}

#pragma mark Object lifecycle

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval
                             repeats:(BOOL)repeats
                               queue:(dispatch_queue_t)queue
                               block:(void (^)(void))block
{
    if (self = [super init]) {
        self.interval = interval;
        self.repeats = repeats;
        self.queue = queue ?: dispatch_get_main_queue();
        self.block = block;

        self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.queue);
        
        @weakify(self)
        dispatch_source_set_event_handler(self.source, ^{
            @strongify(self)
            block();
            if (! repeats) {
                [self invalidate];
            }
        });
    }
    return self;
}

- (void)dealloc
{
    [self invalidate];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithTimeInterval:0. repeats:NO queue:NULL block:^{}];
}

#pragma clang diagnostic pop

#pragma mark Timer management

- (void)resume
{
    if (self.resumed) {
        return;
    }
    
    // Use leeway to let the system optimize when timers are fired
    // See https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/MinimizeTimerUse.html
    // As documented for `NSTimer` tolerance property, a leeway of 10% is a general rule which can significantly improve energy
    // efficiency.
    int64_t intervalNsec = self.interval * NSEC_PER_SEC;
    dispatch_source_set_timer(self.source, dispatch_time(DISPATCH_TIME_NOW, intervalNsec), intervalNsec, intervalNsec / 10.);
    dispatch_resume(self.source);
    
    self.resumed = YES;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidEnterBackground:)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationWillEnterForeground:)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
}

- (void)fire
{
    dispatch_async(self.queue, self.block);
    if (! self.repeats) {
        [self invalidate];
    }
}

- (void)suspend
{
    if (! self.resumed) {
        return;
    }
    
    dispatch_suspend(self.source);
    self.resumed = NO;
}

- (void)invalidate
{
    // See https://forums.developer.apple.com/thread/15902
    if (! self.resumed) {
        [self resume];
    }
    dispatch_source_cancel(self.source);
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

#pragma mark Notifications

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    dispatch_suspend(self.source);
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    dispatch_resume(self.source);
}

@end
