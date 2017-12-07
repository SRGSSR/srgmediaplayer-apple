//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerSceneView.h"

#import "AVPlayer+SRGMediaPlayer.h"
#import "SRGMotionManager.h"
#import "SRGQuaternion.h"
#import "SRGVideoNode.h"
#import "UIDevice+SRGMediaPlayer.h"

#import <libextobjc/libextobjc.h>
#import <SpriteKit/SpriteKit.h>

static void commonInit(SRGMediaPlayerSceneView *self);

@interface SRGMediaPlayerSceneView ()

@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) SCNNode *cameraNode;

@property (nonatomic) SCNQuaternion deviceBasedCameraOrientation;                    // The current device-based orientation for the camera.

@property (nonatomic) CGPoint angularOffsets;                                        // The current angular offsets applied with the pan gesture.
@property (nonatomic) CGPoint initialAngularOffsets;                                 // The angular offsets saved when the pan gesture begins.

@property (nonatomic, weak) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation SRGMediaPlayerSceneView

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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [SRGMotionManager start];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIApplicationDidEnterBackgroundNotification
                                                      object:nil];
        [SRGMotionManager stop];
    }
}

#pragma mark Subclassing hooks

- (void)setupScene:(SCNScene *)scene withCameraNode:(SCNNode *)cameraNode
{}

#pragma marm SCNSceneRendererDelegate protocol

- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
{
    // CMMotionManager might deliver events to a background queue.
    dispatch_async(dispatch_get_main_queue(), ^{
        CMMotionManager *motionManager = [SRGMotionManager motionManager];
        
        // A `CMDeviceMotion` instance is returned only for devices supporting tracking.
        CMDeviceMotion *deviceMotion = motionManager.deviceMotion;
        if (deviceMotion) {
            // Calculate the requird camera orientation based on device orientation, and apply additional adjustements
            // the user made with the pan gesture.
            SCNVector4 deviceBasedCamerOrientation = SRGCameraOrientationForAttitude(deviceMotion.attitude, motionManager.attitudeReferenceFrame);
            self.deviceBasedCameraOrientation = deviceBasedCamerOrientation;
            self.cameraNode.orientation = SRGRotateQuaternion(deviceBasedCamerOrientation, self.angularOffsets.x, self.angularOffsets.y);
        }
    });
}

#pragma mark SRGMediaPlaybackView protocol

- (void)setPlayer:(AVPlayer *)player withAssetDimensions:(CGSize)assetDimensions
{
    self.player = player;
    
    // TODO: Reset cached values
    
    if (player) {
        SCNScene *scene = [SCNScene scene];
        
        SCNNode *cameraNode = [SCNNode node];
        cameraNode.camera = [SCNCamera camera];
        cameraNode.position = SCNVector3Make(0.f, 0.f, 0.f);
        cameraNode.eulerAngles = SCNVector3Make(M_PI, 0.f, 0.f);
        [scene.rootNode addChildNode:cameraNode];
        self.cameraNode = cameraNode;
        
        SKScene *videoScene = [SKScene sceneWithSize:assetDimensions];
        
        SRGVideoNode *videoNode = [[SRGVideoNode alloc] initWithAVPlayer:player];
        videoNode.size = assetDimensions;
        videoNode.position = CGPointMake(assetDimensions.width / 2.f, assetDimensions.height / 2.f);
        [videoScene addChild:videoNode];
        
        // Avoid small radii (< 5) and large ones (> 100), for which the result is incorrect. Anything in between seems
        // fine.
        SCNSphere *sphere = [SCNSphere sphereWithRadius:20.f];
        sphere.firstMaterial.doubleSided = YES;
        sphere.firstMaterial.diffuse.contents = videoScene;
        SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphere];
        sphereNode.position = SCNVector3Make(0.f, 0.f, 0.f);
        [scene.rootNode addChildNode:sphereNode];
        
        [self setupScene:scene withCameraNode:cameraNode];
    }
    else {
        [self setupScene:nil withCameraNode:nil];
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
            CGPoint translation = [panGestureRecognizer translationInView:self];
            
            // Rotation around the x-axis (horizontal through the phone) is obtained with a pan gesture in the y-direction.
            // Similarly for the y-axis. The angle is normalized so that a full gesture across the view would lead to a full
            // rotation in this direction.
            // Also see http://nshipster.com/cmdevicemotion/
            // TODO: Lock up and down
            float wx = 2 * M_PI * translation.y / CGRectGetWidth(self.frame);
            float wy = 2 * M_PI * translation.x / CGRectGetHeight(self.frame);
            
            CGPoint angularOffsets = CGPointMake(wx + self.initialAngularOffsets.x, wy + self.initialAngularOffsets.y);
            self.angularOffsets = angularOffsets;
            self.cameraNode.orientation = SRGRotateQuaternion(self.deviceBasedCameraOrientation, angularOffsets.x,  angularOffsets.y);
            break;
        }
            
        default: {
            break;
        }
    }
}

#pragma mark Notifications

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    // Pause the player in background, but not when locking the device, as for `AVPlayerLayer`-based playback. Unlike
    // usual `AVPlayerLayer`-based playback, `SKVideoNode`-based playback is not automatically paused. To determine
    // whether a background entry is due to the lock screen being enabled or not, we need to wait a little bit.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (! [UIDevice srg_mediaPlayer_isLocked]) {
            [self.player pause];
        }
    });
}

@end

static void commonInit(SRGMediaPlayerSceneView *self)
{
    self.backgroundColor = [UIColor clearColor];
    
    // Let the camera be controlled by a pan gesture
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateCamera:)];
    [self addGestureRecognizer:panGestureRecognizer];
    self.panGestureRecognizer = panGestureRecognizer;
}
