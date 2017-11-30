//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

#import "SRGMediaPlayerFlatView.h"

static void commonInit(SRGMediaPlayerView *self);

@implementation SRGMediaPlayerView

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

- (SRGMediaPlayerFlatView *)flatView
{
    return self.subviews.firstObject;
}

- (AVPlayer *)player
{
    return [self flatView].player;
}

- (void)setPlayer:(AVPlayer *)player
{
    [self flatView].player = player;
}

- (AVPlayerLayer *)playerLayer
{
    return [self flatView].playerLayer;
}

@end

static void commonInit(SRGMediaPlayerView *self)
{
    SRGMediaPlayerFlatView *flatView = [[SRGMediaPlayerFlatView alloc] initWithFrame:self.bounds];
    flatView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:flatView];
}
