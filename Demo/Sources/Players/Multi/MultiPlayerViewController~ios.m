//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MultiPlayerViewController.h"

#import "Resources.h"

#import <libextobjc/libextobjc.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface MultiPlayerViewController ()

@property (nonatomic) NSArray<Media *> *medias;
@property (nonatomic) NSArray<SRGMediaPlayerController *> *mediaPlayerControllers;

@property (nonatomic, weak) IBOutlet UIView *mainPlayerView;
@property (nonatomic, weak) IBOutlet UIView *playersViewContainer;

@property (nonatomic, weak) IBOutlet SRGPlaybackButton *playbackButton;
@property (nonatomic, weak) IBOutlet SRGAirPlayButton *airPlayButton;

@end

@implementation MultiPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithMedias:(NSArray<Media *> *)medias
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:ResourceNameForUIClass(self.class) bundle:nil];
    MultiPlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.medias = medias;
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSMutableArray<SRGMediaPlayerController *> *mediaPlayerControllers = [NSMutableArray array];
    for (Media *media in self.medias) {
        SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
        SRGMediaPlayerView *playerView = mediaPlayerController.view;
        playerView.viewMode = media.is360 ? SRGMediaPlayerViewModeMonoscopic : SRGMediaPlayerViewModeFlat;
        [mediaPlayerController playURL:media.URL];
        [mediaPlayerControllers addObject:mediaPlayerController];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(activatePlayer:)];
        [playerView addGestureRecognizer:tapGestureRecognizer];
    }
    self.mediaPlayerControllers = mediaPlayerControllers.copy;
    
    [self displayMediaPlayerControllers:mediaPlayerControllers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.movingToParentViewController || self.beingPresented) {
        [self updatePlayerLayout];
    }
}

#pragma mark Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updatePlayerLayout];
    } completion:nil];
}

#pragma mark Layout

- (void)updatePlayerLayout
{
    [self.playersViewContainer.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull subview, NSUInteger idx, BOOL * _Nonnull stop) {
        subview.frame = [self rectForPlayerViewAtIndex:idx];
    }];
}

- (CGRect)rectForPlayerViewAtIndex:(NSInteger)index
{
    CGFloat height = CGRectGetHeight(self.playersViewContainer.frame);
    CGFloat width = height * 16.f / 9.f;
    return CGRectMake(index * width, 0.f, width, height);
}

#pragma mark Media players

- (void)displayMediaPlayerControllers:(NSArray<SRGMediaPlayerController *> *)mediaPlayerControllers
{
    [self.playersViewContainer.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull subview, NSUInteger idx, BOOL * _Nonnull stop) {
        [subview removeFromSuperview];
    }];
    
    [mediaPlayerControllers enumerateObjectsUsingBlock:^(SRGMediaPlayerController * _Nonnull mediaPlayerController, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            [mediaPlayerController reloadPlayerConfigurationWithBlock:^(AVPlayer * _Nonnull player) {
                player.allowsExternalPlayback = YES;
                player.usesExternalPlaybackWhileExternalScreenIsActive = YES;
                player.muted = NO;
            }];
            self.playbackButton.mediaPlayerController = mediaPlayerController;
            self.airPlayButton.mediaPlayerController = mediaPlayerController;
            
            UIView *playerView = mediaPlayerController.view;
            playerView.frame = self.mainPlayerView.bounds;
            playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.mainPlayerView addSubview:playerView];
        }
        else {
            [mediaPlayerController reloadPlayerConfigurationWithBlock:^(AVPlayer * _Nonnull player) {
                player.allowsExternalPlayback = NO;
                player.usesExternalPlaybackWhileExternalScreenIsActive = NO;
                player.muted = YES;
            }];
            
            UIView *playerView = mediaPlayerController.view;
            [self.playersViewContainer addSubview:playerView];
        }
    }];
    
    [self updatePlayerLayout];
}

#pragma mark Gesture recognizers

- (void)activatePlayer:(UIGestureRecognizer *)gestureRecognizer
{
    [self.mediaPlayerControllers enumerateObjectsUsingBlock:^(SRGMediaPlayerController * _Nonnull mediaPlayerController, NSUInteger idx, BOOL * _Nonnull stop) {
        SRGMediaPlayerView *playerView = mediaPlayerController.view;
        if (gestureRecognizer.view != playerView) {
            return;
        }
        
        if (playerView.superview == self.mainPlayerView) {
            return;
        }
        
        NSMutableArray<SRGMediaPlayerController *> *mediaPlayerControllers = self.mediaPlayerControllers.mutableCopy;
        [mediaPlayerControllers removeObject:mediaPlayerController];
        [mediaPlayerControllers insertObject:mediaPlayerController atIndex:0];
        [self displayMediaPlayerControllers:mediaPlayerControllers.copy];
    }];
}

#pragma mark Actions

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
