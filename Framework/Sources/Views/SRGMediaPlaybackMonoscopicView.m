//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlaybackMonoscopicView.h"

#import "AVPlayer+SRGMediaPlayer.h"

#import <SpriteKit/SpriteKit.h>

static void commonInit(SRGMediaPlaybackMonoscopicView *self);

@interface SRGMediaPlaybackMonoscopicView ()

@property (nonatomic, weak) SCNView *sceneView;

@end

@implementation SRGMediaPlaybackMonoscopicView

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

- (void)didSetupScene:(SCNScene *)scene withCameraNode:(SCNNode *)cameraNode
{
    [super didSetupScene:scene withCameraNode:cameraNode];
    
    self.sceneView.scene = scene;
    self.sceneView.hidden = NO;
}

@end

#pragma mark Functions

static void commonInit(SRGMediaPlaybackMonoscopicView *self)
{
    SCNView *sceneView = [[SCNView alloc] initWithFrame:self.bounds options:nil];
    sceneView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sceneView.backgroundColor = [UIColor clearColor];
    sceneView.hidden = YES;
    sceneView.delegate = self;
    [self addSubview:sceneView];
    self.sceneView = sceneView;
}
