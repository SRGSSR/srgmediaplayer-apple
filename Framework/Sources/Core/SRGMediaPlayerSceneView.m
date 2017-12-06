//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerSceneView.h"

#import "AVPlayer+SRGMediaPlayer.h"
#import "SRGMotionManager.h"
#import "UIDevice+SRGMediaPlayer.h"

#import <libextobjc/libextobjc.h>
#import <SpriteKit/SpriteKit.h>

static void commonInit(SRGMediaPlayerSceneView *self);

@interface SRGMediaPlayerSceneView ()

@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) SCNNode *cameraNode;

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
        CMDeviceMotion *deviceMotion = [SRGMotionManager motionManager].deviceMotion;
        if (deviceMotion) {
            self.cameraNode.orientation = SRGCameraDirectionForAttitude(deviceMotion.attitude);
        }
    });
}

#pragma mark SRGMediaPlaybackView protocol

- (void)setPlayer:(AVPlayer *)player withAssetDimensions:(CGSize)assetDimensions
{
    self.player = player;
    
    if (player) {
        SCNScene *scene = [SCNScene scene];
        
        SCNNode *cameraNode = [SCNNode node];
        cameraNode.camera = [SCNCamera camera];
        cameraNode.position = SCNVector3Make(0.f, 0.f, 0.f);
        cameraNode.eulerAngles = SCNVector3Make(M_PI, 0.f, 0.f);
        [scene.rootNode addChildNode:cameraNode];
        self.cameraNode = cameraNode;
        
        SKScene *videoScene = [SKScene sceneWithSize:assetDimensions];
        
        SKVideoNode *videoNode = [SKVideoNode videoNodeWithAVPlayer:player];
        videoNode.size = assetDimensions;
        videoNode.position = CGPointMake(assetDimensions.width / 2.f, assetDimensions.height / 2.f);
        [videoScene addChild:videoNode];
        
        SCNSphere *sphere = [SCNSphere sphereWithRadius:100.f];
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
}
