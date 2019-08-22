//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#if TARGET_OS_IOS

#import "SRGRouteDetector.h"

#import "NSTimer+SRGMediaPlayer.h"

#import <AVFoundation/AVFoundation.h>
#import <libextobjc/libextobjc.h>

NSString * const SRGMediaPlayerWirelessRoutesAvailableDidChangeNotification = @"SRGMediaPlayerWirelessRoutesAvailableDidChangeNotification";

static SRGRouteDetector *s_routeDetector;

@interface SRGRouteDetector ()

@property (nonatomic) AVRouteDetector *routeDetector;
@property (nonatomic) BOOL multipleRoutesDetected;

@property (nonatomic) NSTimer *timer;

@end

@implementation SRGRouteDetector

#pragma mark Class methods

+ (void)initialize
{
    if (self != SRGRouteDetector.class) {
        return;
    }
    
    if (@available(iOS 11, *)) {
        s_routeDetector = [[SRGRouteDetector alloc] init];
    }
}

+ (SRGRouteDetector *)sharedRouteDetector
{
    return s_routeDetector;
}

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.routeDetector = [[AVRouteDetector alloc] init];
        
        // According to its documentation, `AVRouteDetector` detection should only be enabled when needed to avoid
        // unnecessary battery consumption. We therefore only periodically enable it and cache the result
        self.timer = [NSTimer srgmediaplayer_timerWithTimeInterval:30. repeats:YES block:^(NSTimer * _Nonnull timer) {
            [self updateRouteAvailability];
        }];
        [self updateRouteAvailability];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationWillEnterForeground:)
                                                   name:UIApplicationWillEnterForegroundNotification
                                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    self.timer = nil;
}

#pragma mark Getters and setters

- (void)setTimer:(NSTimer *)timer
{
    [_timer invalidate];
    _timer = timer;
}

#pragma mark Periodic checks

- (void)updateRouteAvailability
{
    if (! self.routeDetector.routeDetectionEnabled) {
        // Register for the next route update before enabling detection for a short amount of time. After it has
        // been determined, the current status is received with this notification.
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(multipleRoutesDetectedDidChange:)
                                                   name:AVRouteDetectorMultipleRoutesDetectedDidChangeNotification
                                                 object:self.routeDetector];
        self.routeDetector.routeDetectionEnabled = YES;
    }
}

#pragma mark Getters and setters

- (void)setMultipleRoutesDetected:(BOOL)multipleRoutesDetected
{
    NSAssert(NSThread.isMainThread, @"Should be executed on the main thread");
    
    BOOL previousMultipleRoutesDetected = _multipleRoutesDetected;
    _multipleRoutesDetected = multipleRoutesDetected;
    
    if (previousMultipleRoutesDetected != multipleRoutesDetected) {
        [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerWirelessRoutesAvailableDidChangeNotification object:nil];
    }
}

#pragma mark Notification

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self updateRouteAvailability];
}

- (void)multipleRoutesDetectedDidChange:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.multipleRoutesDetected = self.routeDetector.multipleRoutesDetected;
        
        // Stop observing route changes (disabling route detection triggers another notification with no routes
        // found, which we must not listen to).
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:AVRouteDetectorMultipleRoutesDetectedDidChangeNotification
                                                    object:self.routeDetector];
        
        self.routeDetector.routeDetectionEnabled = NO;
    });
}

#pragma mark KVO

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@keypath(SRGRouteDetector.new, multipleRoutesDetected)]) {
        return NO;
    }
    else {
        return [super automaticallyNotifiesObserversForKey:key];
    }
}

@end

#endif
