//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MultiPlayerViewController.h"

#import <libextobjc/libextobjc.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface MultiPlayerViewController ()

@property (nonatomic) NSArray<NSURL *> *mediaURLs;

@property (nonatomic) NSMutableArray<UIView *> *playerViews;
@property (nonatomic) NSMutableArray<SRGMediaPlayerController *> *mediaPlayerControllers;

@property (nonatomic) NSInteger selectedIndex;

@property (nonatomic, weak) IBOutlet UIView *mainPlayerView;
@property (nonatomic, weak) IBOutlet UIView *playerViewsContainer;

@property (nonatomic, weak) IBOutlet SRGPlaybackButton *playPauseButton;

@property (nonatomic) IBOutletCollection(UIView) NSArray *overlayViews;

@end

@implementation MultiPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithMediaURLs:(NSArray<NSURL *> *)mediaURLs
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    MultiPlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.mediaURLs = mediaURLs;
    return viewController;
}

#pragma mark Getters and setters

- (void)setMediaURLs:(NSArray<NSURL *> *)mediaURLs
{
    _mediaURLs = mediaURLs;
    
    NSMutableArray<SRGMediaPlayerController *> *mediaPlayerControllers = [NSMutableArray array];
    for (NSInteger i = 0; i < mediaURLs.count; ++i) {
        SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
        
        @weakify(self)
        mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
            @strongify(self)
            BOOL isMainPlayer = (i == self.selectedIndex);
            player.allowsExternalPlayback = isMainPlayer;
            player.usesExternalPlaybackWhileExternalScreenIsActive = isMainPlayer;
            player.muted = ! isMainPlayer;
        };
        
        UITapGestureRecognizer *switchTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchMainPlayer:)];
        [mediaPlayerController.view addGestureRecognizer:switchTapGestureRecognizer];
        [mediaPlayerControllers addObject:mediaPlayerController];
    }
    self.mediaPlayerControllers = [mediaPlayerControllers copy];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    _selectedIndex = selectedIndex;
    
    SRGMediaPlayerController *mainMediaPlayerController = self.mediaPlayerControllers[selectedIndex];
    [mainMediaPlayerController reloadPlayerConfiguration];
    [self attachPlayer:mainMediaPlayerController toView:self.mainPlayerView];
    
    [self.playerViewsContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.playerViewsContainer layoutIfNeeded];
    
    for (NSInteger index = 0; index < self.mediaPlayerControllers.count; index++) {
        if (index == selectedIndex) {
            continue;
        }
        
        CGRect playerViewFrame = [self rectForPlayerViewAtIndex:self.playerViewsContainer.subviews.count];
        UIView *playerView = [[UIView alloc] initWithFrame:playerViewFrame];
        playerView.backgroundColor = [UIColor blackColor];
        playerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        [self.playerViewsContainer addSubview:playerView];
        
        SRGMediaPlayerController *thumbnailMediaPlayerController = self.mediaPlayerControllers[index];
        [thumbnailMediaPlayerController reloadPlayerConfiguration];
        [self attachPlayer:thumbnailMediaPlayerController toView:playerView];
    }
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setSelectedIndex:0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        for (NSInteger i = 0; i < self.mediaURLs.count; ++i) {
            NSURL *URL = self.mediaURLs[i];
            SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerControllers[i];
            [mediaPlayerController playURL:URL];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        [self.mediaPlayerControllers makeObjectsPerformSelector:@selector(reset)];
    }
}

#pragma mark Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        NSInteger index = 0;
        for (UIView *playerView in self.playerViewsContainer.subviews) {
            playerView.frame = [self rectForPlayerViewAtIndex:index++];
        }
    } completion:nil];
}

#pragma mark Media players

- (CGRect)rectForPlayerViewAtIndex:(NSInteger)index
{
    CGFloat playerWidth = MAX(100, MIN(200, CGRectGetWidth(self.playerViewsContainer.frame) / (self.mediaURLs.count - 1)));
    CGFloat playerHeight = (playerWidth - 10) * 10 / 16;
    
    CGFloat x = self.mediaURLs.count > 2 ? index * playerWidth : (CGRectGetWidth(self.playerViewsContainer.frame) - playerWidth) / 2;
    CGFloat y = CGRectGetHeight(self.playerViewsContainer.frame) / 2 - playerHeight / 2;
    
    return CGRectMake(x + 5, y, playerWidth - 10, playerHeight);
}

- (void)attachPlayer:(SRGMediaPlayerController *)mediaPlayerController toView:(UIView *)playerView
{
    BOOL isMainPlayer = (playerView == self.mainPlayerView);
    if (isMainPlayer) {
        [self.playPauseButton setMediaPlayerController:mediaPlayerController];
    }
    
    mediaPlayerController.view.frame = playerView.bounds;
    mediaPlayerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [playerView insertSubview:mediaPlayerController.view atIndex:0];
    
    UITapGestureRecognizer *defaultTapGestureRecognizer = mediaPlayerController.view.gestureRecognizers.firstObject;
    UITapGestureRecognizer *switchTapGestureRecognizer = mediaPlayerController.view.gestureRecognizers.lastObject;
    defaultTapGestureRecognizer.enabled = isMainPlayer;
    switchTapGestureRecognizer.enabled = ! isMainPlayer;
}

- (SRGMediaPlayerController *)mediaPlayerControllerForPlayerView:(UIView *)playerView
{
    for (SRGMediaPlayerController *mediaPlayerController in self.mediaPlayerControllers) {
        if ([mediaPlayerController.view isEqual:playerView]) {
            return mediaPlayerController;
        }
    }
    return nil;
}

- (NSArray *)thumbnailPlayerControllers
{
    NSMutableArray *thumbnailPlayerControllers = [NSMutableArray array];
    for (SRGMediaPlayerController *mediaPlayerController in self.mediaPlayerControllers) {
        if (! [mediaPlayerController.view.superview isEqual:self.mainPlayerView]) {
            [thumbnailPlayerControllers addObject:mediaPlayerController];
        }
    }
    return [thumbnailPlayerControllers copy];
}

#pragma mark Actions

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark Gesture recognizers

- (void)switchMainPlayer:(UITapGestureRecognizer *)gestureRecognizer
{
    SRGMediaPlayerController *mediaPlayerController = [self mediaPlayerControllerForPlayerView:gestureRecognizer.view];
    self.selectedIndex = [self.mediaPlayerControllers indexOfObject:mediaPlayerController];
}

@end
