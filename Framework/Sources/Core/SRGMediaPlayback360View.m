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

- (void)setupScene:(SCNScene *)scene withCameraNode:(SCNNode *)cameraNode
{
    self.sceneView.scene = scene;
    self.sceneView.hidden = (scene == nil);
}

@end

static void commonInit(SRGMediaPlayback360View *self)
{
    SCNView *sceneView = [[SCNView alloc] initWithFrame:self.bounds options:nil];
    sceneView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sceneView.backgroundColor = [UIColor clearColor];
    sceneView.hidden = YES;
    sceneView.delegate = self;
    [self addSubview:sceneView];
    self.sceneView = sceneView;
}
