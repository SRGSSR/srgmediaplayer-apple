//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGQuaternion.h"

@import simd;

SCNQuaternion SRGRotateQuaternion(SCNQuaternion quaternion, float wx, float wy)
{
    simd_quatf simdQuaternion = simd_quaternion(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
    
    simd_quatf simdRotationAroundX = simd_quaternion(wx, simd_make_float3(1.f, 0.f, 0.f));
    simdQuaternion = simd_mul(simdQuaternion, simdRotationAroundX);
    
    simd_quatf simdRotationAroundY = simd_quaternion(wy, simd_make_float3(0.f, 1.f, 0.f));
    simdQuaternion = simd_mul(simdRotationAroundY, simdQuaternion);
    
    simd_float3 vector = simd_imag(simdQuaternion);
    return SCNVector4Make(vector.x, vector.y, vector.z, simd_real(simdQuaternion));
}

SCNQuaternion SRGQuaternionMakeWithAngleAndAxis(float radians, float x, float y, float z)
{
    simd_quatf simdQuaternion = simd_quaternion(radians, simd_make_float3(x, y, z));
    simd_float3 vector = simd_imag(simdQuaternion);
    return SCNVector4Make(vector.x, vector.y, vector.z, simd_real(simdQuaternion));
}

#if TARGET_OS_IOS

SCNQuaternion SRGCameraOrientationForAttitude(CMAttitude *attitude)
{
    // Based on: https://gist.github.com/travisnewby/96ee1ac2bc2002f1d480
    // Also see https://stackoverflow.com/a/28784841/760435
    CMQuaternion quaternion = attitude.quaternion;
    simd_quatf simdQuaternion = simd_quaternion((float)quaternion.x, (float)quaternion.y, (float)quaternion.z, (float)quaternion.w);
    switch (UIApplication.sharedApplication.statusBarOrientation) {
        case UIInterfaceOrientationPortrait: {
            simd_quatf simdRotationQuaternion = simd_quaternion(M_PI_2, simd_make_float3(1.f, 0.f, 0.f));
            simdQuaternion = simd_mul(simdRotationQuaternion, simdQuaternion);
            simd_float3 vector = simd_imag(simdQuaternion);
            return SCNVector4Make(vector.x, vector.y, vector.z, simd_real(simdQuaternion));
            break;
        }
            
        case UIInterfaceOrientationPortraitUpsideDown: {
            simd_quatf simdRotationQuaternion = simd_quaternion(-M_PI_2, simd_make_float3(1.f, 0.f, 0.f));
            simdQuaternion = simd_mul(simdRotationQuaternion, simdQuaternion);
            simd_float3 vector = simd_imag(simdQuaternion);
            return SCNVector4Make(-vector.x, -vector.y, vector.z, simd_real(simdQuaternion));
            break;
        }
            
        case UIInterfaceOrientationLandscapeLeft: {
            simd_quatf simdRotationQuaternion = simd_quaternion(M_PI_2, simd_make_float3(0.f, 1.f, 0.f));
            simdQuaternion = simd_mul(simdRotationQuaternion, simdQuaternion);
            simd_float3 vector = simd_imag(simdQuaternion);
            return SCNVector4Make(vector.y, -vector.x, vector.z, simd_real(simdQuaternion));
            break;
        }
            
        case UIInterfaceOrientationLandscapeRight: {
            simd_quatf simdRotationQuaternion = simd_quaternion(-M_PI_2, simd_make_float3(0.f, 1.f, 0.f));
            simdQuaternion = simd_mul(simdRotationQuaternion, simdQuaternion);
            simd_float3 vector = simd_imag(simdQuaternion);
            return SCNVector4Make(-vector.y, vector.x, vector.z, simd_real(simdQuaternion));
            break;
        }
            
        default: {
            return SCNVector4Zero;
            break;
        }
    }
}

#endif
