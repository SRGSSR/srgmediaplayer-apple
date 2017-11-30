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
        @weakify(player)
        [player addObserver:self keyPath:@keypath(player.currentItem.tracks) options:0 block:^(MAKVONotification *notification) {
            @strongify(player)
            
            // TODO: See if AVAsset should be used for another reason (it has method to extract tracks of a given type, there
            //       must be some reason)
            NSPredicate *videoPredicate = [NSPredicate predicateWithBlock:^BOOL(AVPlayerItemTrack * _Nullable track, NSDictionary<NSString *, id> * _Nullable bindings) {
                return [track.assetTrack.mediaType isEqualToString:AVMediaTypeVideo];
            }];
            
            AVAssetTrack *assetTrack = [player.currentItem.tracks filteredArrayUsingPredicate:videoPredicate].firstObject.assetTrack;
            if (assetTrack) {
                CGSize size = CGSizeApplyAffineTransform(assetTrack.naturalSize, assetTrack.preferredTransform);
                CGFloat ratio = size.width / size.height;
                
                // 360 videos are provided in equirectangular format (2:1)
                // See https://www.360rize.com/2017/04/5-things-you-should-know-about-360-video-resolution/
                if (ratio == 2.f) {
                    [self flatView].alpha = 0.f;
                }
                else {
                    [self flatView].alpha = 1.f;
                }
            }
            else {
                [self flatView].alpha = 0.f;
            }
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
