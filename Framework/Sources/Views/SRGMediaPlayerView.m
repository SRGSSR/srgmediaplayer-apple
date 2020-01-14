//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "SRGMediaPlaybackMonoscopicView.h"
#import "SRGMediaPlaybackFlatView.h"
#import "SRGMediaPlaybackStereoscopicView.h"

#import <libextobjc/libextobjc.h>

#if TARGET_OS_IOS
static CMMotionManager *s_motionManager = nil;
#endif

static void commonInit(SRGMediaPlayerView *self);

@interface SRGMediaPlayerView ()

@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) UIView<SRGMediaPlaybackView> *playbackView;
@property (nonatomic, getter=isPlaybackViewHidden) BOOL playbackViewHidden;
@property (nonatomic, getter=isReadyForDisplay) BOOL readyForDisplay;

@end

@implementation SRGMediaPlayerView

#pragma mark Class methods

#if TARGET_OS_IOS

+ (CMMotionManager *)motionManager
{
    return s_motionManager;
}

+ (void)setMotionManager:(CMMotionManager *)motionManager
{
    s_motionManager = motionManager;
}

#endif

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

#pragma mark Getters and setters

- (void)setPlayer:(AVPlayer *)player
{
    [_player removeObserver:self keyPath:@keypath(_player.currentItem.presentationSize)];
    [_player removeObserver:self keyPath:@keypath(_player.externalPlaybackActive)];
    
    _player = player;
    
    [player srg_addMainThreadObserver:self keyPath:@keypath(player.currentItem.presentationSize) options:0 block:^(MAKVONotification *notification) {
        [self updateSubviews];
    }];
    [player srg_addMainThreadObserver:self keyPath:@keypath(player.externalPlaybackActive) options:0 block:^(MAKVONotification *notification) {
        [self updateSubviews];
    }];
    
    [self updateSubviewsWithPlayer:player];
}

- (void)setPlaybackView:(UIView<SRGMediaPlaybackView> *)playbackView
{
    [_playbackView.playerLayer removeObserver:self keyPath:@keypath(AVPlayerLayer.new, readyForDisplay)];
    
    _playbackView = playbackView;
    
    [playbackView.playerLayer srg_addMainThreadObserver:self keyPath:@keypath(AVPlayerLayer.new, readyForDisplay) options:0 block:^(MAKVONotification * _Nonnull notification) {
        [self updateReadyForDisplay];
    }];
    [self updateReadyForDisplay];
}

- (void)setViewMode:(SRGMediaPlayerViewMode)viewMode
{
    if (_viewMode == viewMode) {
        return;
    }
    
    _viewMode = viewMode;
    
    [self updateSubviews];
}

- (AVPlayerLayer *)playerLayer
{
    return self.playbackView.playerLayer;
}

- (void)setPlaybackViewHidden:(BOOL)playbackViewHidden
{
    _playbackViewHidden = playbackViewHidden;
    self.playbackView.hidden = [self isPlaybackViewHiddenWithPlayer:self.player];
}

#pragma mark Updates

- (void)updateSubviews
{
    [self updateSubviewsWithPlayer:self.player];
}

- (void)updateSubviewsWithPlayer:(AVPlayer *)player
{
    if (player) {
        CGSize presentationSize = player.currentItem.presentationSize;
        if (! CGSizeEqualToSize(presentationSize, CGSizeZero)) {
            static dispatch_once_t s_onceToken;
            static NSDictionary<NSNumber *, Class> *s_viewClasses;
            dispatch_once(&s_onceToken, ^{
                s_viewClasses = @{ @(SRGMediaPlayerViewModeFlat) : SRGMediaPlaybackFlatView.class,
                                   @(SRGMediaPlayerViewModeMonoscopic) : SRGMediaPlaybackMonoscopicView.class,
#if TARGET_OS_IOS
                                   @(SRGMediaPlayerViewModeStereoscopic) : SRGMediaPlaybackStereoscopicView.class
#endif
                                   };
            });
            
            Class playbackViewClass = s_viewClasses[@(self.viewMode)];
            if (! [self.playbackView isKindOfClass:playbackViewClass]) {
                [self.playbackView setPlayer:nil withAssetDimensions:CGSizeZero];
                [self.playbackView removeFromSuperview];
                
                UIView<SRGMediaPlaybackView> *playbackView = [[playbackViewClass alloc] initWithFrame:self.bounds];
                playbackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [self addSubview:playbackView];
                self.playbackView = playbackView;
            }
            
            if (self.playbackView.player != player) {
                [self.playbackView setPlayer:player withAssetDimensions:presentationSize];
            }
            
            self.playbackView.hidden = [self isPlaybackViewHiddenWithPlayer:player];
        }
    }
    else {
        [self.playbackView setPlayer:nil withAssetDimensions:CGSizeZero];
        [self.playbackView removeFromSuperview];
    }
}

- (void)updateReadyForDisplay
{
    self.readyForDisplay = self.playbackView.playerLayer.readyForDisplay;
}

- (BOOL)isPlaybackViewHiddenWithPlayer:(AVPlayer *)player
{
    return player.externalPlaybackActive || self.playbackViewHidden;
}

@end

static void commonInit(SRGMediaPlayerView *self)
{
    self.viewMode = SRGMediaPlayerViewModeFlat;
}
