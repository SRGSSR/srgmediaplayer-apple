//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGQuaternion.h"

#import <GLKit/GLKit.h>

SCNQuaternion SRGCameraOrientationForAttitude(CMAttitude *attitude)
{
    // Based on: https://gist.github.com/travisnewby/96ee1ac2bc2002f1d480
    CMQuaternion quaternion = attitude.quaternion;
    GLKQuaternion glkQuaternion = GLKQuaternionMake(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait: {
            GLKQuaternion glkRotationQuaternion = GLKQuaternionMakeWithAngleAndAxis(M_PI_2, 1.f, 0.f, 0.f);
            glkQuaternion = GLKQuaternionMultiply(glkRotationQuaternion, glkQuaternion);
            return SCNVector4Make(glkQuaternion.x, glkQuaternion.y, glkQuaternion.z, glkQuaternion.w);
            break;
        }
            
        case UIInterfaceOrientationPortraitUpsideDown: {
            GLKQuaternion glkRotationQuaternion = GLKQuaternionMakeWithAngleAndAxis(-M_PI_2, 1.f, 0.f, 0.f);
            glkQuaternion = GLKQuaternionMultiply(glkRotationQuaternion, glkQuaternion);
            return SCNVector4Make(-glkQuaternion.x, -glkQuaternion.y, glkQuaternion.z, glkQuaternion.w);
            break;
        }
            
        case UIInterfaceOrientationLandscapeLeft: {
            GLKQuaternion glkRotationQuaternion = GLKQuaternionMakeWithAngleAndAxis(M_PI_2, 0.f, 1.f, 0.f);
            glkQuaternion = GLKQuaternionMultiply(glkRotationQuaternion, glkQuaternion);
            return SCNVector4Make(glkQuaternion.y, -glkQuaternion.x, glkQuaternion.z, glkQuaternion.w);
            break;
        }
            
        case UIInterfaceOrientationLandscapeRight: {
            GLKQuaternion glkRotationQuaternion = GLKQuaternionMakeWithAngleAndAxis(-M_PI_2, 0.f, 1.f, 0.f);
            glkQuaternion = GLKQuaternionMultiply(glkRotationQuaternion, glkQuaternion);
            return SCNVector4Make(-glkQuaternion.y, glkQuaternion.x, glkQuaternion.z, glkQuaternion.w);
            break;
        }
            
        default: {
            return SCNVector4Zero;
            break;
        }
    }
}

SCNQuaternion SRGRotateQuaternion(SCNQuaternion quaternion, float wx, float wy)
{
    GLKQuaternion glkQuaternion = GLKQuaternionMake(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
    
    GLKQuaternion glkRotationAroundX = GLKQuaternionMakeWithAngleAndAxis(wx, 1.f, 0.f, 0.f);
    glkQuaternion = GLKQuaternionMultiply(glkQuaternion, glkRotationAroundX);
    
    GLKQuaternion glkRotationAroundY = GLKQuaternionMakeWithAngleAndAxis(wy, 0.f, 1.f, 0.f);
    glkQuaternion = GLKQuaternionMultiply(glkRotationAroundY, glkQuaternion);
    
    return SCNVector4Make(glkQuaternion.x, glkQuaternion.y, glkQuaternion.z, glkQuaternion.w);
}

SCNQuaternion SRGQuaternionMakeWithAngleAndAxis(float radians, float x, float y, float z)
{
    GLKQuaternion glkQuaternion = GLKQuaternionMakeWithAngleAndAxis(radians, x, y, z);
    return SCNVector4Make(glkQuaternion.x, glkQuaternion.y, glkQuaternion.z, glkQuaternion.w);
}
