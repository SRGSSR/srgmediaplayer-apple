//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS
@import CoreMotion;
#endif

@import SceneKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  A default reference-counted internal motion manager.
 */
API_UNAVAILABLE(tvos)
@interface SRGMotionManager : NSObject

/**
 *  Start and stop the motion manager. If one has been provided (@see `SRGMediaPlayerView.h`), these operations
 *  do nothing, as the application is then responsible of starting and stopping the model manager it registered.
 */
+ (void)start;
+ (void)stop;

#if TARGET_OS_IOS

/**
 *  The Core Motion manager to use. If one has been provided (@see `SRGMediaPlayerView.h`), it will be returned
 *  instead.
 */
@property (class, nonatomic, readonly) CMMotionManager *motionManager;

#endif

@end

NS_ASSUME_NONNULL_END
