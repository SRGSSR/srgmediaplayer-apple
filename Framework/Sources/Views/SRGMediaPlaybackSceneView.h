//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView+Private.h"

#import <SceneKit/SceneKit.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Common SceneKit-based view for 360°-related playback, which is obtained by rendering the video into a texture mapped
 *  onto a sphere, at the center of which a camera is placed.
 *
 *  This class takes care of all standard tasks required by 360° playback:
 *    - Scene setup.
 *    - Camera controls (via device motions or pan gesture).
 *
 *  Subclasses are responsible of creating and managing the view layout. To establish the relationship with the
 *  underlying scene and camera, they must also override the `-didSetupScene:withCameraNode:` method.
 */
@interface SRGMediaPlaybackSceneView : UIView <SCNSceneRendererDelegate, SRGMediaPlaybackView>

/**
 *  Method called when the scene has been setup.
 *
 *  @param scene  The scene which has been setup, if any.
 *  @param camera The main camera installed within the scene, if any.
 */
- (void)didSetupScene:(nullable SCNScene *)scene withCameraNode:(nullable SCNNode *)cameraNode NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
