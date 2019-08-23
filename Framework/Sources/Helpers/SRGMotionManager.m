//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMotionManager.h"

#import "SRGMediaPlayerView+Private.h"

#import <GLKit/GLKit.h>

#if TARGET_OS_IOS

static SRGMotionManager *s_motionManager = nil;

@interface SRGMotionManager () {
    NSUInteger _useCount;
}

@property (nonatomic) CMMotionManager *coreMotionManager;

@end

@implementation SRGMotionManager

+ (SRGMotionManager *)defaultMotionManager
{
    static dispatch_once_t s_onceToken;
    static SRGMotionManager *s_motionManager;
    dispatch_once(&s_onceToken, ^{
        s_motionManager = [[SRGMotionManager alloc] init];
    });
    return s_motionManager;
}

+ (void)start
{
    if (! SRGMediaPlayerView.motionManager) {
        [[SRGMotionManager defaultMotionManager] start];
    }
}

+ (void)stop
{
    if (! SRGMediaPlayerView.motionManager) {
        [[SRGMotionManager defaultMotionManager] stop];
    }
}

+ (CMMotionManager *)motionManager
{
    return SRGMediaPlayerView.motionManager ?: [self defaultMotionManager].coreMotionManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.coreMotionManager = [[CMMotionManager alloc] init];
        self.coreMotionManager.deviceMotionUpdateInterval = 1. / 60.;
    }
    return self;
}

- (void)start
{
    ++_useCount;
    
    if (_useCount == 1) {
        [self.coreMotionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
    }
}

- (void)stop
{
    if (_useCount == 0) {
        return;
    }
    
    --_useCount;
    
    if (_useCount == 0) {
        [self.coreMotionManager stopDeviceMotionUpdates];
    }
}

@end

#endif
