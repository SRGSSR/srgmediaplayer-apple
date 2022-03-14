//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGPlaybackSettingsButton.h"

#import "AVAudioSession+SRGMediaPlayer.h"
#import "AVMediaSelectionGroup+SRGMediaPlayer.h"
#import "AVPlayerItem+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "SRGMediaPlayerNavigationController.h"
#import "SRGPlaybackSettingsViewController.h"
#import "UIWindow+SRGMediaPlayer.h"

@import libextobjc;

static void commonInit(SRGPlaybackSettingsButton *self);

@interface SRGPlaybackSettingsButton () <SRGPlaybackSettingsViewControllerDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) UIButton *button;
@property (nonatomic, weak) UIButton *fakeInterfaceBuilderButton;

@end

@implementation SRGPlaybackSettingsButton

@synthesize image = _image;

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

- (void)dealloc
{
    self.mediaPlayerController = nil;       // Unregister everything
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.playbackState)];
        
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerSubtitleTrackDidChangeNotification
                                                    object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self updateAppearanceForMediaPlayerController:mediaPlayerController];
    
    if (mediaPlayerController) {
        @weakify(self)
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.playbackState) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateAppearance];
        }];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(subtitleTrackDidChange:)
                                                   name:SRGMediaPlayerSubtitleTrackDidChangeNotification
                                                 object:mediaPlayerController];
    }
}

- (UIImage *)image
{
    return _image ?: [UIImage imageNamed:@"more" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self updateAppearance];
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self updateAppearance];
    }
}

- (CGSize)intrinsicContentSize
{
    if (self.fakeInterfaceBuilderButton) {
        return self.fakeInterfaceBuilderButton.intrinsicContentSize;
    }
    else {
        return self.button.intrinsicContentSize;
    }
}

#pragma mark UI

- (void)updateAppearance
{
    [self updateAppearanceForMediaPlayerController:self.mediaPlayerController];
}

- (void)updateAppearanceForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    AVPlayerItem *playerItem = mediaPlayerController.player.currentItem;
    AVAsset *asset = playerItem.asset;
    
    if (self.fakeInterfaceBuilderButton) {
        self.hidden = NO;
    }
    else {
        self.hidden = NO;
        [self.button setImage:self.image forState:UIControlStateNormal];
    }
}

#pragma mark SRGPlaybackSettingsViewControllerDelegate protocol

- (void)playbackSettingsViewControllerWasDismissed:(id)playbackSettingsViewController
{
    if ([self.delegate respondsToSelector:@selector(playbackSettingsButtonDidHideSettings:)]) {
        [self.delegate playbackSettingsButtonDidHideSettings:self];
    }
}

#pragma mark UIPopoverPresentationControllerDelegate protocol

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
    if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        if (@available(iOS 13, *)) {
            return UIModalPresentationAutomatic;
        }
        else {
            controller.presentedViewController.modalPresentationCapturesStatusBarAppearance = YES;
            return UIModalPresentationOverFullScreen;
        }
    }
    else {
        controller.presentedViewController.modalPresentationCapturesStatusBarAppearance = NO;
        return UIModalPresentationPopover;
    }
}

#pragma mark Actions

- (void)showTracks:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(playbackSettingsButtonWillShowSettings:)]) {
        [self.delegate playbackSettingsButtonWillShowSettings:self];
    }
    
    SRGPlaybackSettingsViewController *viewViewController = [[SRGPlaybackSettingsViewController alloc] initWithMediaPlayerController:self.mediaPlayerController
                                                                                                                  userInterfaceStyle:self.userInterfaceStyle];
    viewViewController.delegate = self;
    viewViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                         target:self
                                                                                                         action:@selector(hideTracks:)];
    SRGMediaPlayerNavigationController *navigationController = [[SRGMediaPlayerNavigationController alloc] initWithRootViewController:viewViewController];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navigationController.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popoverPresentationController = navigationController.popoverPresentationController;
        popoverPresentationController.delegate = self;
        popoverPresentationController.sourceView = self;
        popoverPresentationController.sourceRect = self.bounds;
    }
    else if (@available(iOS 13, *)) {
        navigationController.modalPresentationStyle = UIModalPresentationAutomatic;
    }
    else {
        navigationController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        
        // Only `UIModalPresentationFullScreen` makes status bar control transferred to the presented view controller automatic.
        // For other modes this has to be enabled explicitly.
        navigationController.modalPresentationCapturesStatusBarAppearance = YES;
    }
    
    UIViewController *topViewController = self.window.srg_topViewController;
    [topViewController presentViewController:navigationController
                                    animated:YES
                                  completion:nil];
}

- (void)hideTracks:(id)sender
{
    UIViewController *topViewController = self.window.srg_topViewController;
    [topViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    
    // Use a fake button for Interface Builder rendering. Using the normal button added in commonInit does not work
    // correctly with Interface Builder preview in all cases, since the preview lifecycle is probably different from
    // the view lifecycle when the application is run on iOS. When the view is wrapped into a stack view, the
    // intrinsic size is namely incorrect, leading to layout issues. It seems that using a button added in
    // -prepareForInterfaceBuilder works, though
    UIButton *fakeInterfaceBuilderButton = [UIButton buttonWithType:UIButtonTypeSystem];
    fakeInterfaceBuilderButton.frame = self.bounds;
    fakeInterfaceBuilderButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    fakeInterfaceBuilderButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    UIImage *image = [UIImage imageNamed:@"more" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
    [fakeInterfaceBuilderButton setImage:image forState:UIControlStateNormal];
    
    [self addSubview:fakeInterfaceBuilderButton];
    self.fakeInterfaceBuilderButton = fakeInterfaceBuilderButton;
    
    // Hide the normal button
    self.button.hidden = YES;
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return SRGMediaPlayerLocalizedString(@"Playback settings", @"Accessibility title of playback settings button");
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

- (NSArray *)accessibilityElements
{
    return nil;
}

#pragma mark Notifications

- (void)subtitleTrackDidChange:(NSNotification *)notification
{
    [self updateAppearance];
}

@end

#pragma mark Functions

static void commonInit(SRGPlaybackSettingsButton *self)
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = self.bounds;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    button.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [button addTarget:self action:@selector(showTracks:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    self.button = button;
    
    self.hidden = YES;
}

#endif
