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

@interface SRGMediaPlayerViewController ()

@property (nonatomic) SRGMediaPlayerController *controller;
@property (nonatomic, weak) SRGMediaPlayerView *playerView;

@end

@implementation SRGMediaPlayerViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.controller = [[SRGMediaPlayerController alloc] init];
        
        @weakify(self)
        [self.controller addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, player) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            self.player = self.controller.player;
        }];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackDidFail:)
                                                   name:SRGMediaPlayerPlaybackDidFailNotification
                                                 object:self.controller];
    }
    return self;
}

#pragma mark Getters and setters

- (SRGMediaPlayerViewMode)viewMode
{
    return self.controller.view.viewMode;
}

- (void)setViewMode:(SRGMediaPlayerViewMode)viewMode
{
    self.controller.view.viewMode = viewMode;
}

#pragma mark View lifecycle

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (! self.playerView) {
        UIView *originalPlayerView = SRGMediaPlayerViewControllerPlayerSubview(self.view);
        if (originalPlayerView) {
            SRGMediaPlayerView *playerView = self.controller.view;
            playerView.viewMode = self.viewMode;
            
            playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            playerView.frame = originalPlayerView.superview.bounds;
            [originalPlayerView.superview insertSubview:playerView belowSubview:originalPlayerView];
            [originalPlayerView removeFromSuperview];
            
            self.playerView = playerView;
        }
    }
}

#pragma mark Notifications

- (void)playbackDidFail:(NSNotification *)notification
{
    // `AVPlayerViewController` displays failures only if a failing `AVPlayer` is attached to it. Since `SRGMediaPlayerController`
    // sets its player 
    NSURL *URL = [NSURL URLWithString:@"failed://"];
    self.player = [AVPlayer playerWithURL:URL];
}

@end
