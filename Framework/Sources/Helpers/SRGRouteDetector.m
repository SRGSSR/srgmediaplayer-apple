//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGRouteDetector.h"

#import "NSTimer+SRGMediaPlayer.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

NSString * const SRGMediaPlayerWirelessRoutesAvailableDidChangeNotification = @"SRGMediaPlayerWirelessRoutesAvailableDidChangeNotification";
NSString * const SRGMediaPlayerWirelessRouteActiveDidChangeNotification = @"SRGMediaPlayerWirelessRouteActiveDidChangeNotification";

static SRGRouteDetector *s_routeDetector;

@interface SRGRouteDetector ()

@property (nonatomic) MPVolumeView *volumeView;
@property (nonatomic) AVRouteDetector *routeDetector API_AVAILABLE(ios(11.0));

@property (nonatomic) BOOL multipleRoutesDetected;

@property (nonatomic) NSTimer *timer;

@end

@implementation SRGRouteDetector

#pragma mark Class methods

+ (SRGRouteDetector *)sharedRouteDetector
{
    return s_routeDetector;
}

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (@available(iOS 11, *)) {
                self.routeDetector = [[AVRouteDetector alloc] init];
            }
            else {
                self.volumeView = [[MPVolumeView alloc] initWithFrame:CGRectZero];
                self.volumeView.hidden = YES;
            }
            [self updateRouteAvailability];
            
            self.timer = [NSTimer srgmediaplayer_timerWithTimeInterval:30. repeats:YES block:^(NSTimer * _Nonnull timer) {
                [self updateRouteAvailability];
            }];
            
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(applicationWillEnterForeground:)
                                                       name:UIApplicationWillEnterForegroundNotification
                                                     object:nil];
        });
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

// According to its documentation, `AVRouteDetector` detection should only be enabled when needed to avoid
// unnecessary battery consumption. It is likely that `MPVolumeView` suffers from the same issues. We therefore
// implement a periodic update mechanism for both.
- (void)updateRouteAvailability
{
    if (@available(iOS 11, *)) {
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
    else {
        // For certain routes to be detected (e.g. AirPlay), the view must be installed in a hiearchy, see
        //   https://developer.apple.com/documentation/mediaplayer/mpvolumeview/1620073-wirelessroutesavailable?language=objc
        // otherwise `wirelessRoutesAvailable` incorrectly returns `NO`.
        //
        // Moreover, no more than one volume view reports correct information.
        UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
        if (keyWindow) {
            [keyWindow insertSubview:self.volumeView atIndex:0];
            self.multipleRoutesDetected = self.volumeView.wirelessRoutesAvailable;
            [self.volumeView removeFromSuperview];
        }
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
    if (@available(iOS 11, *)) {
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
}

@end

__attribute__((constructor)) static void SRGRouteDetectorInit(void)
{
    s_routeDetector = [[SRGRouteDetector alloc] init];
}
