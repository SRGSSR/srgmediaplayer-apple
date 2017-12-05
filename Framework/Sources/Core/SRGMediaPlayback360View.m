//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayback360View.h"

#import "AVPlayer+SRGMediaPlayer.h"

#import <SpriteKit/SpriteKit.h>

static void commonInit(SRGMediaPlayback360View *self);

@interface SRGMediaPlayback360View ()

@property (nonatomic, weak) SCNView *sceneView;

@end

@implementation SRGMediaPlayback360View

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

- (void)setPlayer:(AVPlayer *)player
{
    super.player = player;
    
    SCNScene *scene = [SCNScene scene];
    self.sceneView.scene = scene;
    
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
    SCNView *sceneView = [[SCNView alloc] initWithFrame:self.bounds options:nil];
    sceneView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sceneView.delegate = self;
    [self addSubview:sceneView];
    self.sceneView = sceneView;
}
