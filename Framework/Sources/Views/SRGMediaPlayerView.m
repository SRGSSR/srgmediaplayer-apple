//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

#import "AVPlayer+SRGMediaPlayer.h"
#import "AVPlayerItem+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "SRGMediaPlaybackMonoscopicView.h"
#import "SRGMediaPlaybackFlatView.h"
#import "SRGMediaPlaybackStereoscopicView.h"

#import <libextobjc/libextobjc.h>



static void commonInit(SRGMediaPlayerView *self);

@interface SRGMediaPlayerView ()

@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) UIView<SRGMediaPlaybackView> *playbackView;
@property (nonatomic, getter=isPlaybackViewHidden) BOOL playbackViewHidden;

@end

@implementation SRGMediaPlayerView

#pragma mark Class methods



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
    [_player removeObserver:self keyPath:@keypath(_player.currentItem.tracks)];
    [_player removeObserver:self keyPath:@keypath(_player.externalPlaybackActive)];
    
    _player = player;
    
    [player srg_addMainThreadObserver:self keyPath:@keypath(player.currentItem.tracks) options:0 block:^(MAKVONotification *notification) {
        [self updateSubviews];
    }];
    [player srg_addMainThreadObserver:self keyPath:@keypath(player.externalPlaybackActive) options:0 block:^(MAKVONotification *notification) {
        [self updateSubviews];
    }];
    
    [self updateSubviewsWithPlayer:player];
}

- (void)setViewMode:(SRGMediaPlayerViewMode)viewMode
{
    if (_viewMode == viewMode) {
        return;
    }
    
    _viewMode = viewMode;
    
    [self updateSubviewsWithPlayer:self.player];
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
        AVAssetTrack *videoAssetTrack = [player.currentItem srg_assetTracksWithMediaType:AVMediaTypeVideo].firstObject;
        if (videoAssetTrack) {
            CGSize assetDimensions = CGSizeApplyAffineTransform(videoAssetTrack.naturalSize, videoAssetTrack.preferredTransform);
            
            // Asset dimension is not always immediately available from the asset track. Skip updates until this
            // information is available
            if (CGSizeEqualToSize(assetDimensions, CGSizeZero)) {
                return;
            }
            
            static dispatch_once_t s_onceToken;
            static NSDictionary<NSNumber *, Class> *s_viewClasses;
            dispatch_once(&s_onceToken, ^{
                s_viewClasses = @{ @(SRGMediaPlayerViewModeFlat) : SRGMediaPlaybackFlatView.class,
                                   @(SRGMediaPlayerViewModeMonoscopic) : SRGMediaPlaybackMonoscopicView.class,
                                   @(SRGMediaPlayerViewModeStereoscopic) : SRGMediaPlaybackStereoscopicView.class };
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
                [self.playbackView setPlayer:player withAssetDimensions:assetDimensions];
            }
            
            self.playbackView.hidden = [self isPlaybackViewHiddenWithPlayer:player];
        }
        else {
            // During seeks, we might have no tracks at all. Skip updates until tracks are available.
            AVAssetTrack *audioAssetTrack = [player.currentItem srg_assetTracksWithMediaType:AVMediaTypeAudio].firstObject;
            if (! audioAssetTrack) {
                return;
            }
        }
    }
    else {
        [self.playbackView setPlayer:nil withAssetDimensions:CGSizeZero];
        [self.playbackView removeFromSuperview];
    }
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
