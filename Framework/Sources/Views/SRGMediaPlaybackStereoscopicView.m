//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlaybackStereoscopicView.h"

#import "AVPlayer+SRGMediaPlayer.h"

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

- (void)didSetupScene:(SCNScene *)scene withCameraNode:(SCNNode *)cameraNode
{
    [super didSetupScene:scene withCameraNode:cameraNode];
    
    self.leftEyeSceneView.scene = scene;
    self.leftEyeSceneView.hidden = NO;
    
    self.rightEyeSceneView.scene = scene;
    self.rightEyeSceneView.hidden = NO;
    
    SCNNode *leftEyeCameraNode = [SCNNode node];
    leftEyeCameraNode.camera = [SCNCamera camera];
    leftEyeCameraNode.position = SCNVector3Make(-0.5f, 0.f, 0.f);
    [cameraNode addChildNode:leftEyeCameraNode];
    self.leftEyeSceneView.pointOfView = leftEyeCameraNode;
    
    SCNNode *rightEyeCameraNode = [SCNNode node];
    rightEyeCameraNode.camera = [SCNCamera camera];
    rightEyeCameraNode.position = SCNVector3Make(0.5f, 0.f, 0.f);
    [cameraNode addChildNode:rightEyeCameraNode];
    self.rightEyeSceneView.pointOfView = rightEyeCameraNode;
}

@end

#pragma mark Functions

static void commonInit(SRGMediaPlaybackStereoscopicView *self)
{
    SCNView *leftEyeSceneView = [[SCNView alloc] initWithFrame:CGRectZero options:nil];
    leftEyeSceneView.hidden = YES;
    leftEyeSceneView.playing = YES;                // Ensures both scenes play at the same time
    leftEyeSceneView.delegate = self;
    [self addSubview:leftEyeSceneView];
    self.leftEyeSceneView = leftEyeSceneView;
    
    SCNView *rightEyeSceneView = [[SCNView alloc] initWithFrame:CGRectZero options:nil];
    rightEyeSceneView.hidden = YES;
    rightEyeSceneView.playing = YES;                // Ensures both scenes play at the same time
    rightEyeSceneView.delegate = self;
    [self addSubview:rightEyeSceneView];
    self.rightEyeSceneView = rightEyeSceneView;
}
