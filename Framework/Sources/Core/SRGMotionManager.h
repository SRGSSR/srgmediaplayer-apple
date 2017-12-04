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
 *  Return the camera direction to apply, corresponding to a Core Motion attitude and reference frame.
 */
// TODO: Depending on the reference frame used for the motion manager, the values need to be tweaked for a correct
//       result. This function must therefore expect the reference frame as parameter, and behave accordingly.
// TODO: Could be moved into a category onf CMMotionManager, would be better.
OBJC_EXTERN SCNVector4 SRGCameraDirectionForAttitude(CMAttitude *attitude);

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
