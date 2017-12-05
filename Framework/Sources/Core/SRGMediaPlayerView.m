//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

#import "AVPlayer+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "SRGMediaPlayback360View.h"
#import "SRGMediaPlaybackFlatView.h"
#import "SRGMediaPlaybackStereoscopicView.h"

#import <libextobjc/libextobjc.h>

SRGMediaPlayerViewMode const SRGMediaPlayerViewModeFlat = @"flat";
SRGMediaPlayerViewMode const SRGMediaPlayerViewMode360 = @"360";
SRGMediaPlayerViewMode const SRGMediaPlayerViewModeStereoscopic = @"stereoscopic";

static CMMotionManager *s_motionManager = nil;

@interface SRGMediaPlayerView ()

@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) UIView<SRGMediaPlaybackView> *playbackView;

@property (nonatomic) NSArray<SRGMediaPlayerViewMode> *supportedViewModes;

@end

@implementation SRGMediaPlayerView

@synthesize viewMode = _viewMode;

#pragma mark Class methods

+ (CMMotionManager *)motionManager
{
    return s_motionManager;
}

+ (void)setMotionManager:(CMMotionManager *)motionManager
{
    s_motionManager = motionManager;
}

#pragma mark Getters and setters

- (void)setPlayer:(AVPlayer *)player
{
    [_player removeObserver:self keyPath:@keypath(_player.currentItem.tracks)];
    
    _player = player;
    
    [player srg_addMainThreadObserver:self keyPath:@keypath(player.currentItem.tracks) options:0 block:^(MAKVONotification *notification) {
        [self updateWithPlayer:player];
    }];
    
    [self updateWithPlayer:player];
}

- (SRGMediaPlayerViewMode)viewMode
{
    return _viewMode ?: self.supportedViewModes.firstObject;
}

- (void)setViewMode:(SRGMediaPlayerViewMode)viewMode
{
    if (_viewMode == viewMode) {
        return;
    }
    
    if (viewMode && [self.supportedViewModes containsObject:viewMode]) {
        _viewMode = viewMode;
    }
    else {
        _viewMode = nil;
    }
    
    [self updatePlaybackViewWithPlayer:self.player];
}

- (AVPlayerLayer *)playerLayer
{
    return self.playbackView.playerLayer;
}

#pragma mark Updates

- (void)updateWithPlayer:(AVPlayer *)player
{
    CGSize assetDimensions = player.srg_assetDimensions;
    if (player) {
        if (! CGSizeEqualToSize(assetDimensions, CGSizeZero)) {
            // 360 videos are provided in equirectangular format (2:1)
            // See https://www.360rize.com/2017/04/5-things-you-should-know-about-360-video-resolution/
            CGFloat ratio = assetDimensions.width / assetDimensions.height;
            if (ratio == 2.f) {
                self.supportedViewModes = @[SRGMediaPlayerViewMode360, SRGMediaPlayerViewModeStereoscopic];
            }
            else {
                self.supportedViewModes = @[SRGMediaPlayerViewModeFlat];
            }
        }
    }
    else {
        self.supportedViewModes = nil;
    }
    
    if (self.viewMode && ! [self.supportedViewModes containsObject:self.viewMode]) {
        self.viewMode = nil;
    }
        
    [self updatePlaybackViewWithPlayer:player];
}

- (void)updatePlaybackViewWithPlayer:(AVPlayer *)player
{
    static dispatch_once_t s_onceToken;
    static NSDictionary *s_viewClasses;
    dispatch_once(&s_onceToken, ^{
        s_viewClasses = @{ SRGMediaPlayerViewModeFlat : [SRGMediaPlaybackFlatView class],
                           SRGMediaPlayerViewMode360 : [SRGMediaPlayback360View class],
                           SRGMediaPlayerViewModeStereoscopic : [SRGMediaPlaybackStereoscopicView class] };
    });
    
    if (self.viewMode) {
        Class playbackViewClass = s_viewClasses[self.viewMode];
        NSAssert(playbackViewClass != Nil, @"View mode must be officially supported");
        if (! [self.playbackView isKindOfClass:playbackViewClass]) {
            [self.playbackView removeFromSuperview];
            
            UIView<SRGMediaPlaybackView> *playbackView = [[playbackViewClass alloc] initWithFrame:self.bounds];
            playbackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:playbackView];
            self.playbackView = playbackView;
        }
        
        if (self.playbackView.player != player) {
            self.playbackView.player = player;
        }
    }
    else {
        [self.playbackView removeFromSuperview];
    }
}

@end
