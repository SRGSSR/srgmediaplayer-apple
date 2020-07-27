//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlaybackSceneView.h"

#import "SRGMotionManager.h"
#import "SRGQuaternion.h"
#import "SRGVideoNode.h"

@import libextobjc;
@import SpriteKit;

/**
 *  To manipulate node orientation, use quaternions only. Those are more robust against singularities than Euler
 *  angles. For a quick introduction, see e.g.
 *    http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-17-quaternions/.
 */

static void commonInit(SRGMediaPlaybackSceneView *self);

@interface SRGMediaPlaybackSceneView ()

@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) SCNNode *cameraNode;
@property (nonatomic, weak) SCNSphere *sphere;

@property (nonatomic) SCNQuaternion deviceBasedCameraOrientation;                    // The current device-based orientation for the camera.

@property (nonatomic) CGPoint angularOffsets;                                        // The current angular offsets applied with the pan gesture.
@property (nonatomic) CGPoint initialAngularOffsets;                                 // The angular offsets saved when the pan gesture begins.

@end

@implementation SRGMediaPlaybackSceneView

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

- (void)dealloc
{
    // FIXME: iOS 9 issue: There is a retain cycle with SKVideoNode. At least we can mitigate this issue by
    //        removing the material and pausing the player.
    //        See https://github.com/NYTimes/ios-360-videos/issues/46 for more information.
    //
    //        Remove this code (and the sphere property) once iOS 9 is the minimum supported version.
    if ([NSProcessInfo processInfo].operatingSystemVersion.majorVersion == 9) {
        self.sphere.firstMaterial.diffuse.contents = nil;
        [self.player pause];
    }
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
#if TARGET_OS_IOS
    if (newWindow) {
        [SRGMotionManager start];
    }
    else {
        [SRGMotionManager stop];
    }
#endif
}

#pragma mark Subclassing hooks

- (void)didSetupScene:(SCNScene *)scene withCameraNode:(SCNNode *)cameraNode
{}

#pragma marm SCNSceneRendererDelegate protocol

- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
{
    // CMMotionManager might deliver events to a background queue.
    dispatch_async(dispatch_get_main_queue(), ^{
#if TARGET_OS_IOS
        CMMotionManager *motionManager = SRGMotionManager.motionManager;
        
        // Calculate the required camera orientation based on device orientation (if available), and apply additional
        // adjustements the user made with the pan gesture.
        CMDeviceMotion *deviceMotion = motionManager.deviceMotion;
        
        UIInterfaceOrientation interfaceOrientation;
#if !TARGET_OS_MACCATALYST
        if (@available(iOS 13, *)) {
#endif
            interfaceOrientation = self.window.windowScene.interfaceOrientation;
#if !TARGET_OS_MACCATALYST
        }
        else {
            interfaceOrientation = UIApplication.sharedApplication.statusBarOrientation;
        }
#endif
            
        SCNQuaternion deviceBasedCameraOrientation = deviceMotion ? SRGCameraOrientationForAttitude(deviceMotion.attitude, interfaceOrientation) : SRGQuaternionMakeWithAngleAndAxis(M_PI, 1.f, 0.f, 0.f);
#else
        SCNQuaternion deviceBasedCameraOrientation = SRGQuaternionMakeWithAngleAndAxis(M_PI, 1.f, 0.f, 0.f);
#endif
        self.deviceBasedCameraOrientation = deviceBasedCameraOrientation;
        self.cameraNode.orientation = SRGRotateQuaternion(deviceBasedCameraOrientation, self.angularOffsets.x, self.angularOffsets.y);
    });
}

#pragma mark SRGMediaPlaybackView protocol

- (void)setPlayer:(AVPlayer *)player withAssetDimensions:(CGSize)assetDimensions
{
    self.player = player;
    
    // Reset stored values set by user interaction.
    self.angularOffsets = CGPointZero;
    
    if (player) {
        SCNScene *scene = [SCNScene scene];
        
        SCNNode *cameraNode = [SCNNode node];
        cameraNode.camera = [SCNCamera camera];
        cameraNode.position = SCNVector3Make(0.f, 0.f, 0.f);
        [scene.rootNode addChildNode:cameraNode];
        self.cameraNode = cameraNode;
        
        SKScene *videoScene = [SKScene sceneWithSize:assetDimensions];
        videoScene.backgroundColor = UIColor.clearColor;
        
        SRGVideoNode *videoNode = [[SRGVideoNode alloc] initWithAVPlayer:player];
        videoNode.size = assetDimensions;
        videoNode.position = CGPointMake(assetDimensions.width / 2.f, assetDimensions.height / 2.f);
        [videoScene addChild:videoNode];
        
        // Avoid small radii (< 5) and large ones (> 100), for which the result is incorrect. Anything in between seems fine.
        SCNSphere *sphere = [SCNSphere sphereWithRadius:20.f];
        sphere.firstMaterial.doubleSided = YES;
        sphere.firstMaterial.diffuse.contents = videoScene;
        self.sphere = sphere;
        
        SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphere];
        sphereNode.position = SCNVector3Make(0.f, 0.f, 0.f);
        [scene.rootNode addChildNode:sphereNode];
        
        [self didSetupScene:scene withCameraNode:cameraNode];
    }
}

- (AVPlayerLayer *)playerLayer
{
    // No player layer is available
    return nil;
}

#pragma mark Actions

- (void)rotateCamera:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            self.initialAngularOffsets = self.angularOffsets;
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            // Prevent interactions outside the view bounds
            CGPoint location = [panGestureRecognizer locationInView:self];
            if (! CGRectContainsPoint(self.bounds, location)) {
                break;
            }
            
            CGPoint translation = [panGestureRecognizer translationInView:self];
            
            // Rotation around the x-axis (horizontal through the phone) is obtained with a pan gesture in the y-direction.
            // Similarly for the y-axis. The angle is normalized so that a full gesture across the view would lead to a half
            // rotation in this direction.
            // Also see http://nshipster.com/cmdevicemotion/
            float wx = M_PI_2 * translation.y / CGRectGetHeight(self.frame);
            float wy = -M_PI * translation.x / CGRectGetWidth(self.frame);
            
            CGPoint angularOffsets = CGPointMake(wx + self.initialAngularOffsets.x, wy + self.initialAngularOffsets.y);
            self.angularOffsets = angularOffsets;
            self.cameraNode.orientation = SRGRotateQuaternion(self.deviceBasedCameraOrientation, angularOffsets.x, angularOffsets.y);
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            self.initialAngularOffsets = CGPointZero;
            break;
        }
            
        default: {
            break;
        }
    }
}

@end

static void commonInit(SRGMediaPlaybackSceneView *self)
{
    self.backgroundColor = UIColor.clearColor;
    
    // Let the camera be controlled by a pan gesture
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateCamera:)];
    [self addGestureRecognizer:panGestureRecognizer];
}
