//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlaybackStereoscopicView.h"

#import "AVPlayer+SRGMediaPlayer.h"

#import <SpriteKit/SpriteKit.h>

static void commonInit(SRGMediaPlaybackStereoscopicView *self);

@interface SRGMediaPlaybackStereoscopicView ()

@property (nonatomic, weak) SCNView *leftEyeSceneView;
@property (nonatomic, weak) SCNView *rightEyeSceneView;

@end

@implementation SRGMediaPlaybackStereoscopicView

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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat eyeWidth = CGRectGetWidth(self.bounds) / 2.f;
    CGFloat eyeHeight = CGRectGetHeight(self.bounds);
    
    self.leftEyeSceneView.frame = CGRectMake(0.f, 0.f, eyeWidth, eyeHeight);
    self.rightEyeSceneView.frame = CGRectMake(eyeWidth, 0.f, eyeWidth, eyeHeight);
}

- (void)setPlayer:(AVPlayer *)player
{
    super.player = player;
    
    SCNScene *scene = [SCNScene scene];
    self.leftEyeSceneView.scene = scene;
    self.rightEyeSceneView.scene = scene;
    
    SCNNode *leftEyeCameraNode = [SCNNode node];
    leftEyeCameraNode.camera = [SCNCamera camera];
    leftEyeCameraNode.position = SCNVector3Make(-0.5f, 0.f, 0.f);
    [scene.rootNode addChildNode:leftEyeCameraNode];
    self.leftEyeSceneView.pointOfView = leftEyeCameraNode;
    self.leftEyeSceneView.playing = YES;                // Ensures both scenes play at the same time
    
    SCNNode *rightEyeCameraNode = [SCNNode node];
    rightEyeCameraNode.camera = [SCNCamera camera];
    rightEyeCameraNode.position = SCNVector3Make(0.5f, 0.f, 0.f);
    [scene.rootNode addChildNode:rightEyeCameraNode];
    self.rightEyeSceneView.pointOfView = rightEyeCameraNode;
    self.rightEyeSceneView.playing = YES;                // Ensures both scenes play at the same time
    
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.position = SCNVector3Make(0.f, 0.f, 0.f);
    [cameraNode addChildNode:leftEyeCameraNode];
    [cameraNode addChildNode:rightEyeCameraNode];
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

static void commonInit(SRGMediaPlaybackStereoscopicView *self)
{
    SCNView *leftEyeSceneView = [[SCNView alloc] initWithFrame:CGRectZero options:nil];
    leftEyeSceneView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    leftEyeSceneView.delegate = self;
    [self addSubview:leftEyeSceneView];
    self.leftEyeSceneView = leftEyeSceneView;
    
    SCNView *rightEyeSceneView = [[SCNView alloc] initWithFrame:CGRectZero options:nil];
    rightEyeSceneView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    rightEyeSceneView.delegate = self;
    [self addSubview:rightEyeSceneView];
    self.rightEyeSceneView = rightEyeSceneView;
}
