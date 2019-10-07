//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerViewController.h"

#import "SRGMediaPlayerView+Private.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

static UIView *SRGMediaPlayerViewControllerPlayerSubview(UIView *view)
{
    if ([view.layer isKindOfClass:AVPlayerLayer.class]) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView *playerSubview = SRGMediaPlayerViewControllerPlayerSubview(subview);
        if (playerSubview) {
            return playerSubview;
        }
    }
    
    return nil;
}

static UIView *SRGMediaPlayerViewControllerAudioOnlySubview(UIView *view)
{
    if ([NSStringFromClass(view.class) containsString:@"AudioOnly"]) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView *audioOnlySubview = SRGMediaPlayerViewControllerAudioOnlySubview(subview);
        if (audioOnlySubview) {
            return audioOnlySubview;
        }
    }
    
    return nil;
}

/**
 *  Subclassing is officially not recommended: https://developer.apple.com/documentation/avkit/avplayerviewcontroller.
 *
 *  We are doing very few changes in this subclass, though, so this should be a perfectly fine approach at the moment.
 *  Wrapping `AVPlayerViewController` as child view controller would be possible, but:
 *    - API methods would need to be mirrored. This would make it possible to restrict `AVPlayerViewController` API to
 *      only a meaningful safer subset, but would also prevent users from benefiting from `AVPlayerViewController` API
 *      improvements automatically.
 *    - The dismissal interactive animation is lost.
 *    - A play button placeholder would be initially displayed, before content actually begins to play.
 *
 *  For these reasons, the subclass approach currently seems a better fit.
 */
@interface SRGMediaPlayerViewController ()

@property (nonatomic) SRGMediaPlayerController *controller;

@end

@implementation SRGMediaPlayerViewController

@dynamic delegate;

#pragma mark Object lifecycle

- (instancetype)initWithController:(SRGMediaPlayerController *)controller
{
    if (self = [super init]) {
        if (! controller) {
            controller = [[SRGMediaPlayerController alloc] init];
        }
        self.controller = controller;
        
        @weakify(self)
        [controller addObserver:self keyPath:@keypath(controller.player) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updatePlayer];
        }];
        [self updatePlayer];
        
        [controller addObserver:self keyPath:@keypath(controller.segments) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self reloadData];
        }];
        [self reloadData];
        
        [controller addObserver:self keyPath:@keypath(controller.view.playbackViewHidden) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateView];
        }];
        [self updateView];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackDidFail:)
                                                   name:SRGMediaPlayerPlaybackDidFailNotification
                                                 object:controller];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithController:nil];
}

- (void)dealloc
{
    // Reattach the player to the original controller view.
    [self setMediaPlayer:nil];
}

#pragma mark Getters and setters

- (AVPlayer *)mediaPlayer
{
    return [self performSelector:@selector(player)];
}

- (void)setMediaPlayer:(AVPlayer *)player
{
    // Make sure the player is never bound to another layer than `AVPlayerViewController` one, otherwise video playback
    // freezes in the simulator (only, but still annoying and probably a bad sign).
    self.controller.view.player = player ? nil : self.mediaPlayer;
    
    // The `player` property has been marked as non-available, use a trick to avoid compiler issues in this file
    [self performSelector:@selector(setPlayer:) withObject:player];
    
    [self reloadData];
    [self updateView];
}

#pragma mark Data

- (void)reloadData
{
#if TARGET_OS_TV
    AVPlayerItem *playerItem = self.controller.player.currentItem;
    
    if ([self.delegate respondsToSelector:@selector(playerViewControllerExternalMetadata:)]) {
        playerItem.externalMetadata = [self.delegate playerViewControllerExternalMetadata:self] ?: @[];
    }
    else {
        playerItem.externalMetadata = @[];
    }
    
    // Register blocked segments as interstitials, so that the seek bar does not provide any preview for such sections.
    NSMutableArray<AVInterstitialTimeRange *> *interstitialTimeRanges = [NSMutableArray array];
    NSMutableArray<id<SRGSegment>> *visibleSegments = [NSMutableArray array];
    
    [self.controller.segments enumerateObjectsUsingBlock:^(id<SRGSegment> _Nonnull segment, NSUInteger idx, BOOL * _Nonnull stop) {
        if (segment.srg_blocked) {
            AVInterstitialTimeRange *interstitialTimeRange = [[AVInterstitialTimeRange alloc] initWithTimeRange:segment.srg_timeRange];
            [interstitialTimeRanges addObject:interstitialTimeRange];
        }
        else if (! segment.srg_hidden) {
            [visibleSegments addObject:segment];
        }
    }];
    
    playerItem.interstitialTimeRanges = interstitialTimeRanges.copy;
    
    NSArray<AVTimedMetadataGroup *> *navigationMarkers = nil;
    if (visibleSegments.count != 0 && [self.delegate respondsToSelector:@selector(playerViewController:navigationMarkersForSegments:)]) {
        navigationMarkers = [self.delegate playerViewController:self navigationMarkersForSegments:visibleSegments] ?: @[];
    }
    
    if (navigationMarkers.count != 0) {
        AVNavigationMarkersGroup *segmentsNavigationMarkerGroup = [[AVNavigationMarkersGroup alloc] initWithTitle:nil /* No title must be set, otherwise marker titles will be overridden */ timedNavigationMarkers:navigationMarkers];
        playerItem.navigationMarkerGroups = @[ segmentsNavigationMarkerGroup ];
    }
    else {
        playerItem.navigationMarkerGroups = @[];
    }
#endif
}

#pragma mark Updates

- (void)updatePlayer
{
    [self setMediaPlayer:self.controller.player];
}

- (void)updateView
{
    UIView *playerView = SRGMediaPlayerViewControllerPlayerSubview(self.view);
    playerView.hidden = self.controller.view.playbackViewHidden;
    
#if TARGET_OS_TV
    UIView *audioOnlyView = SRGMediaPlayerViewControllerAudioOnlySubview(self.view);
    [audioOnlyView removeFromSuperview];
#endif
}

#pragma mark Notifications

- (void)playbackDidFail:(NSNotification *)notification
{
    // `AVPlayerViewController` displays failures only if a failing `AVPlayer` is attached to it. Since `SRGMediaPlayerController`
    // sets its player 
    NSURL *URL = [NSURL URLWithString:@"failed://"];
    AVPlayer *failedPlayer = [AVPlayer playerWithURL:URL];
    [self setMediaPlayer:failedPlayer];
}

@end
