//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayback360View.h"

#import "AVPlayer+SRGMediaPlayer.h"
#import "SRGMotionManager.h"
#import "UIDevice+SRGMediaPlayer.h"

#import <SpriteKit/SpriteKit.h>

static void commonInit(SRGMediaPlayback360View *self);

@interface SRGMediaPlayback360View ()

@property (nonatomic, weak) SCNNode *cameraNode;

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

static void commonInit(SRGMediaPlayback360View *self)
{
    self.delegate = self;
}
