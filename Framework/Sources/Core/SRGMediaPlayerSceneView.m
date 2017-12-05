//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerSceneView.h"

#import "SRGMotionManager.h"
#import "UIDevice+SRGMediaPlayer.h"

static void commonInit(SRGMediaPlayerSceneView *self);

@implementation SRGMediaPlayerSceneView

@synthesize player = _player;

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [SRGMotionManager start];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIApplicationDidEnterBackgroundNotification
                                                      object:nil];
        [SRGMotionManager stop];
    }
}

#pragma marm SCNSceneRendererDelegate protocol

- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
{
    // CMMotionManager might deliver events to a background queue.
    dispatch_async(dispatch_get_main_queue(), ^{
        CMDeviceMotion *deviceMotion = [SRGMotionManager motionManager].deviceMotion;
        if (deviceMotion) {
            self.cameraNode.orientation = SRGCameraDirectionForAttitude(deviceMotion.attitude);
        }
    });
}

#pragma mark SRGMediaPlaybackView protocol

- (AVPlayerLayer *)playerLayer
{
    // No player layer is available
    return nil;
}

#pragma mark Notifications

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    // Pause the player in background, but not when locking the device, as for `AVPlayerLayer`-based playback. Unlike
    // usual `AVPlayerLayer`-based playback, `SKVideoNode`-based playback is not automatically paused. To determine
    // whether a background entry is due to the lock screen being enabled or not, we need to wait a little bit.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (! [UIDevice srg_mediaPlayer_isLocked]) {
            [self.player pause];
        }
    });
}

@end

static void commonInit(SRGMediaPlayerSceneView *self)
{
    self.backgroundColor = [UIColor blackColor];
}
