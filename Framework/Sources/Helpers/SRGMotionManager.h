//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMotion/CoreMotion.h>
#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A default reference-counted internal motion manager.
 */
@interface SRGMotionManager : NSObject

/**
 *  Start and stop the motion manager. If one has been provided (@see `SRGMediaPlayerView.h`), these operations
 *  do nothing, as the application is then responsible of starting and stopping the model manager it registered.
 */
+ (void)start;
+ (void)stop;

/**
 *  The Core Motion manager to use. If one has been provided (@see `SRGMediaPlayerView.h`), it will be returned
 *  instead.
 */
+ (CMMotionManager *)motionManager;

@end

NS_ASSUME_NONNULL_END
