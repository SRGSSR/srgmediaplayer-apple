//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

#import "SRGMediaPlayerFlatView.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

static void commonInit(SRGMediaPlayerView *self);

@interface SRGMediaPlayerView ()

@property (nonatomic) AVPlayer *player;

@end

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

- (void)setPlayer:(AVPlayer *)player
{
    if (_player) {
        [_player removeObserver:self keyPath:@keypath(_player.currentItem.tracks)];
    }
    
    _player = player;
    
    [self flatView].player = player;
    
    if (player) {
        [player addObserver:self keyPath:@keypath(player.currentItem.tracks) options:0 block:^(MAKVONotification *notification) {
            // TODO: Branch on the correct view depending on the video type
        }];
    }
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
