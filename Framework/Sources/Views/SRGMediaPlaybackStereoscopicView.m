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
    self.leftEyeSceneView.hidden = (scene == nil);
    
    self.rightEyeSceneView.scene = scene;
    self.rightEyeSceneView.hidden = (scene == nil);
    
    if (cameraNode) {
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
    else {
        self.leftEyeSceneView.pointOfView = nil;
        self.rightEyeSceneView.pointOfView = nil;
    }
}

@end

#pragma mark Functions

static void commonInit(SRGMediaPlaybackStereoscopicView *self)
{
    SCNView *leftEyeSceneView = [[SCNView alloc] initWithFrame:CGRectZero options:nil];
    leftEyeSceneView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    leftEyeSceneView.backgroundColor = [UIColor clearColor];
    leftEyeSceneView.hidden = YES;
    leftEyeSceneView.playing = YES;                // Ensures both scenes play at the same time
    leftEyeSceneView.delegate = self;
    [self addSubview:leftEyeSceneView];
    self.leftEyeSceneView = leftEyeSceneView;
    
    SCNView *rightEyeSceneView = [[SCNView alloc] initWithFrame:CGRectZero options:nil];
    rightEyeSceneView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    rightEyeSceneView.backgroundColor = [UIColor clearColor];
    rightEyeSceneView.hidden = YES;
    rightEyeSceneView.playing = YES;                // Ensures both scenes play at the same time
    rightEyeSceneView.delegate = self;
    [self addSubview:rightEyeSceneView];
    self.rightEyeSceneView = rightEyeSceneView;
}
