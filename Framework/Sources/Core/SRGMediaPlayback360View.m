//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayback360View.h"

#import "AVPlayer+SRGMediaPlayer.h"

#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>
#import <SpriteKit/SpriteKit.h>

static void commonInit(SRGMediaPlayback360View *self);

// TODO: Depending on the reference frame used for the motion manager, the values need to be tweaked for a correct
//       result. This function must therefore expect the reference frame as parameter, and behave accordingly.
static SCNVector4 SRGCameraDirectionForAttitude(CMAttitude *attitude)
{
    // Based on: https://gist.github.com/travisnewby/96ee1ac2bc2002f1d480
    CMQuaternion quaternion = attitude.quaternion;
    
    GLKQuaternion aq = GLKQuaternionMake(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait: {
            GLKQuaternion cq = GLKQuaternionMakeWithAngleAndAxis(M_PI_2, 1.f, 0.f, 0.f);
            GLKQuaternion q = GLKQuaternionMultiply(cq, aq);
            return SCNVector4Make(q.x, q.y, q.z, q.w);
            break;
        }
            
        case UIInterfaceOrientationPortraitUpsideDown: {
            GLKQuaternion cq = GLKQuaternionMakeWithAngleAndAxis(-M_PI_2, 1.f, 0.f, 0.f);
            GLKQuaternion q = GLKQuaternionMultiply(cq, aq);
            return SCNVector4Make(-q.x, -q.y, q.z, q.w);
            break;
        }
            
        case UIInterfaceOrientationLandscapeLeft: {
            GLKQuaternion cq = GLKQuaternionMakeWithAngleAndAxis(M_PI_2, 0.f, 1.f, 0.f);
            GLKQuaternion q = GLKQuaternionMultiply(cq, aq);
            return SCNVector4Make(q.y, -q.x, q.z, q.w);
            break;
        }
            
        case UIInterfaceOrientationLandscapeRight: {
            GLKQuaternion cq = GLKQuaternionMakeWithAngleAndAxis(-M_PI_2, 0.f, 1.f, 0.f);
            GLKQuaternion q = GLKQuaternionMultiply(cq, aq);
            return SCNVector4Make(-q.y, q.x, q.z, q.w);
            break;
        }
            
        default: {
            return SCNVector4Zero;
            break;
        }
    }
}

@interface SRGMediaPlayback360View ()

@property (nonatomic, weak) SCNNode *cameraNode;
@property (nonatomic) CMMotionManager *motionManager;

@end

@implementation SRGMediaPlayback360View

@synthesize player = _player;

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

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
    }
    else {
        [self.motionManager stopDeviceMotionUpdates];
    }
}

#pragma marm SCNSceneRendererDelegate protocol

- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
{
    dispatch_async(dispatch_get_main_queue(), ^{
        CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
        if (deviceMotion) {
            self.cameraNode.orientation = SRGCameraDirectionForAttitude(deviceMotion.attitude);
        }
    });
}

#pragma mark SRGMediaPlaybackView protocol

- (AVPlayerLayer *)playerLayer
{
    // No player layer is available
    return nil;
}

- (void)setPlayer:(AVPlayer *)player
{
    _player = player;
    
    SCNScene *scene = [SCNScene scene];
    self.scene = scene;
    
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    cameraNode.position = SCNVector3Make(0.f, 0.f, 0.f);
    [scene.rootNode addChildNode:cameraNode];
    self.cameraNode = cameraNode;
    
    CGSize size = player.srg_assetDimensions;
    SKScene *videoScene = [SKScene sceneWithSize:size];
    
    SKVideoNode *videoNode = [SKVideoNode videoNodeWithAVPlayer:player];
    videoNode.size = size;
    videoNode.position = CGPointMake(size.width / 2.f, size.height / 2.f);
    [videoScene addChild:videoNode];
    
    SCNSphere *sphere = [SCNSphere sphereWithRadius:100.f];
    sphere.firstMaterial.doubleSided = YES;
    sphere.firstMaterial.diffuse.contents = videoScene;
    SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphere];
    sphereNode.position = SCNVector3Make(0.f, 0.f, 0.f);
    [scene.rootNode addChildNode:sphereNode];
}

@end

static void commonInit(SRGMediaPlayback360View *self)
{
    // TODO: It is recommended to have a single instance for the whole app. Move elsewhere
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 1. / 60.;
    
    self.delegate = self;
}
