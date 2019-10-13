//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerViewController.h"

#import "SRGMediaPlayerController+Private.h"
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

#if TARGET_OS_TV

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
 *  Workaround info pane (here called "info center") not being able to adjust its layout to its content. The info pane
 *  is namely cached, thus preventing its layout from being created again. The following API provides all that is required
 *  to force a refresh when appropriate.
 */
@interface UIViewController (SRGMediaPlayerViewControllerInfoCenter)

/**
 *  Reset the info pane so that its layout can be recreated from scratch.
 */
- (void)srgmediaplayer_resetInfoCenter;

/**
 *  Returns `YES` iff the info pane is displayed.
 */
- (BOOL)srgmediaplayer_isInfoCenterDisplayed;

/**
 *  Show the info pane.
 */
- (void)srgmediaplayer_showInfoCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;

/**
 *  Hide the info pane.
 */
- (BOOL)srgmediaplayer_hideInfoCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;

@end

#endif

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
    [self.controller unbindFromCurrentPlayerViewController];
}

#pragma mark Getters and setters

- (void)setMediaPlayer:(AVPlayer *)player
{
    [self.controller bindToPlayerViewController:self];
    [self reloadData];
    [self updateView];
}

#pragma mark Data

#if TARGET_OS_TV

- (void)reloadInterstitials
{
    AVPlayerItem *playerItem = self.controller.player.currentItem;
    
    // Register blocked segments as interstitials, so that the seek bar does not provide any mean of peeking into
    // for such sections.
    NSMutableArray<AVInterstitialTimeRange *> *interstitialTimeRanges = [NSMutableArray array];
    
    [self.controller.segments enumerateObjectsUsingBlock:^(id<SRGSegment> _Nonnull segment, NSUInteger idx, BOOL * _Nonnull stop) {
        if (segment.srg_blocked) {
            AVInterstitialTimeRange *interstitialTimeRange = [[AVInterstitialTimeRange alloc] initWithTimeRange:segment.srg_timeRange];
            [interstitialTimeRanges addObject:interstitialTimeRange];
        }
    }];
    
    // The seek bar interrupts user interaction when interstitials are reloaded. Only reload when a change has been
    // detected.
    NSArray<AVInterstitialTimeRange *> *previousInterstitialTimeRanges = playerItem.interstitialTimeRanges ?: @[];
    if (! [interstitialTimeRanges isEqualToArray:previousInterstitialTimeRanges]) {
        playerItem.interstitialTimeRanges = interstitialTimeRanges.copy;
    }
}

// Returns `YES` iff the external metadata has been updated.
- (BOOL)reloadExternalMetadata
{
    NSArray<AVMetadataItem *> *externalMetadata = nil;
    if ([self.delegate respondsToSelector:@selector(playerViewControllerExternalMetadata:)]) {
        externalMetadata = [self.delegate playerViewControllerExternalMetadata:self] ?: @[];
    }
    else {
        externalMetadata = @[];
    }
    
    AVPlayerItem *playerItem = self.controller.player.currentItem;
    NSArray<AVMetadataItem *> *previousExternalMetadata = playerItem.externalMetadata ?: @[];
    if (! [externalMetadata isEqualToArray:previousExternalMetadata]) {
        playerItem.externalMetadata = externalMetadata;
        return YES;
    }
    else {
        return NO;
    }
}

// Returns `YES` iff navigation markers have been updated.
- (BOOL)reloadNavigationMarkers
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id<SRGSegment> _Nullable segment, NSDictionary<NSString *,id> * _Nullable bindings) {
        return ! segment.srg_hidden;
    }];
    NSArray<id<SRGSegment>> *visibleSegments = [self.controller.segments filteredArrayUsingPredicate:predicate];
    
    NSArray<AVTimedMetadataGroup *> *navigationMarkers = nil;
    if (visibleSegments.count != 0 && [self.delegate respondsToSelector:@selector(playerViewController:navigationMarkersForSegments:)]) {
        navigationMarkers = [self.delegate playerViewController:self navigationMarkersForSegments:visibleSegments] ?: @[];
    }
    else {
        navigationMarkers = @[];
    }
    
    AVPlayerItem *playerItem = self.controller.player.currentItem;
    NSArray<AVTimedMetadataGroup *> *previousNavigationMarkers = playerItem.navigationMarkerGroups.firstObject.timedNavigationMarkers ?: @[];
    if (! [navigationMarkers isEqualToArray:previousNavigationMarkers]) {
        // The `timedNavigationMarkers` list cannot be empty, otherwise `AVNavigationMarkersGroup` creation crashes.
        if (navigationMarkers.count != 0) {
            AVNavigationMarkersGroup *segmentsNavigationMarkerGroup = [[AVNavigationMarkersGroup alloc] initWithTitle:nil /* No title must be set, otherwise marker titles will be overridden */ timedNavigationMarkers:navigationMarkers];
            playerItem.navigationMarkerGroups = @[ segmentsNavigationMarkerGroup ];
        }
        else {
            playerItem.navigationMarkerGroups = @[];
        }
        return YES;
    }
    else {
        return NO;
    }
}

#endif

- (void)reloadData
{
#if TARGET_OS_TV
    [self reloadInterstitials];
    
    BOOL hasChanges = NO;
    if ([self reloadExternalMetadata]) {
        hasChanges = YES;
    }
    if ([self reloadNavigationMarkers]) {
        hasChanges = YES;
    }
    
    // The information panel does not support reloading with no changes well (scroll position is lost and animations
    // are reset). Only update when something changed.
    if (hasChanges) {
        UIViewController *controlsViewController = self.childViewControllers.firstObject;
        if (controlsViewController) {
            if ([controlsViewController srgmediaplayer_isInfoCenterDisplayed]) {
                [controlsViewController srgmediaplayer_hideInfoCenterAnimated:NO completion:^{
                    [controlsViewController srgmediaplayer_resetInfoCenter];
                    [controlsViewController srgmediaplayer_showInfoCenterAnimated:NO completion:nil];
                }];
            }
            else {
                [controlsViewController srgmediaplayer_resetInfoCenter];
            }
        }
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

#if TARGET_OS_TV

@implementation UIViewController (SRGMediaPlayerViewControllerInfoCenter)

- (void)srgmediaplayer_resetInfoCenter
{
    NSString *ivarName = [[[NSString stringWithFormat:@"12_i346n7893f23o6798P9a432n23el7V43i2e45w78C9o2345n67t1r1234o67l90le0r"] componentsSeparatedByCharactersInSet:NSCharacterSet.decimalDigitCharacterSet] componentsJoinedByString:@""];
    Ivar ivar = class_getInstanceVariable(self.class, ivarName.UTF8String);
    if (ivar) {
        object_setIvar(self, ivar, nil);
    }
}

- (BOOL)srgmediaplayer_isInfoCenterDisplayed
{
    NSString *selectorName = [[[NSString stringWithFormat:@"1i23s557I7n89f05o35P7a23n4556e7A889c12t2i34v4e5"] componentsSeparatedByCharactersInSet:NSCharacterSet.decimalDigitCharacterSet] componentsJoinedByString:@""];
    SEL selector = NSSelectorFromString(selectorName);
    BOOL (*imp)(id, SEL) = (BOOL (*)(id, SEL))method_getImplementation(class_getInstanceMethod(self.class, selector));
    if (imp) {
        return imp(self, selector);
    }
    else {
        return NO;
    }
}

- (void)srgmediaplayer_showInfoCenterAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSString *selectorName = [[[NSString stringWithFormat:@"135s5h77o4w3I6n8f6o4P3a2n4e5A6n7i8m5a4t47e8d9:0c9o675m5p3l2e3t4i5o6n788:12"] componentsSeparatedByCharactersInSet:NSCharacterSet.decimalDigitCharacterSet] componentsJoinedByString:@""];
    SEL selector = NSSelectorFromString(selectorName);
    void (*imp)(id, SEL, BOOL, id) = (void (*)(id, SEL, BOOL, id))method_getImplementation(class_getInstanceMethod(self.class, selector));
    if (imp) {
        imp(self, selector, animated, completion);
    }
    else {
        completion();
    }
}

- (BOOL)srgmediaplayer_hideInfoCenterAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSString *selectorName = [[[NSString stringWithFormat:@"767h753i9d08e453I3n4f66o81P22a34n5e6A7n8i4m28a9t90e2d1:2c56o74m4p2l3e4t7i8o9n0:009"] componentsSeparatedByCharactersInSet:NSCharacterSet.decimalDigitCharacterSet] componentsJoinedByString:@""];
    SEL selector = NSSelectorFromString(selectorName);
    BOOL (*imp)(id, SEL, BOOL, id) = (BOOL (*)(id, SEL, BOOL, id))method_getImplementation(class_getInstanceMethod(self.class, selector));
    if (imp) {
        return imp(self, selector, animated, completion);
    }
    else {
        return NO;
    }
}

@end

#endif
