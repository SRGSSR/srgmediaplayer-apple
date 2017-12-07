//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMotion/CoreMotion.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return a quaternion describing the camera orientation which should be used when the device is held with a
 *  given attitude (orientation in space), so that it always faces the content in front of the device.
 *
 *  @param attitude       The current device orientation in space, as returned by a `CMMotionManager` instance.
 *  @param referenceFrame The reference frame in which the attitude must be interpreted. This corresponds to the
 *                        value used when starting the `CMMotionManager`.
 *
 *  @return The quaternion for the camera orientation.
 *
 *  @see `CMAttitude` documentation for more information.
 */
OBJC_EXTERN SCNQuaternion SRGCameraOrientationForAttitude(CMAttitude *attitude, CMAttitudeReferenceFrame referenceFrame);

/**
 *  Rotate the specified quaternion around the x- and y-axis.
 *
 *  @param quaternion The quaternion to rotate.
 *  @param wx         Angle around the x-axis.
 *  @param wy         Angle around the y-axis.
 *
 *  @return The rotated quaternion.
 */
OBJC_EXTERN SCNQuaternion SRGRotateQuaternion(SCNQuaternion quaternion, float wx, float wy);

/**
 *  Create a quaternion for a rotation around the specified axis.
 */
OBJC_EXTERN SCNQuaternion SRGQuaternionMakeWithAngleAndAxis(float radians, float x, float y, float z);

NS_ASSUME_NONNULL_END
