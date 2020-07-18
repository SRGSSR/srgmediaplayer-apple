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
 *  Rotate the specified quaternion around the x- and y-axis.
 *
 *  @param quaternion The quaternion to rotate.
 *  @param wx         Angle around the x-axis.
 *  @param wy         Angle around the y-axis.
 *
 *  @return The rotated quaternion.
 */
OBJC_EXPORT SCNQuaternion SRGRotateQuaternion(SCNQuaternion quaternion, float wx, float wy);

/**
 *  Create a quaternion for a rotation around the specified axis.
 */
OBJC_EXPORT SCNQuaternion SRGQuaternionMakeWithAngleAndAxis(float radians, float x, float y, float z);

#if TARGET_OS_IOS

/**
 *  Return a quaternion describing the camera orientation which should be used when the device is held with a
 *  given attitude (orientation in space), so that it always faces the content in front of the device.
 *
 *  @param attitude The current device orientation in space, as returned by a `CMMotionManager` instance.
 *
 *  @return The quaternion for the camera orientation.
 *
 *  @see `CMAttitude` documentation for more information.
 */
OBJC_EXTERN SCNQuaternion SRGCameraOrientationForAttitude(CMAttitude *attitude);

#endif

NS_ASSUME_NONNULL_END
