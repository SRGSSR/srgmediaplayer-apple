//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGTracksButton.h"

#import "AVAudioSession+SRGMediaPlayer.h"
#import "AVMediaSelectionGroup+SRGMediaPlayer.h"
#import "AVPlayerItem+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "SRGAlternateTracksViewController.h"
#import "SRGMediaPlayerNavigationController.h"
#import "UIWindow+SRGMediaPlayer.h"

@import libextobjc;

static void commonInit(SRGTracksButton *self);

@interface SRGTracksButton () <SRGAlternateTracksViewControllerDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) UIButton *button;
@property (nonatomic, weak) UIButton *fakeInterfaceBuilderButton;

@end

@implementation SRGTracksButton

@synthesize image = _image;
@synthesize selectedImage = _selectedImage;

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
    return _image ?: [UIImage imageNamed:@"alternate_tracks" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self updateAppearance];
}

- (UIImage *)selectedImage
{
    return _selectedImage ?: [UIImage imageNamed:@"alternate_tracks_selected" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
}

- (void)setSelectedImage:(UIImage *)selectedImage
{
    _selectedImage = selectedImage;
    [self updateAppearance];
}

- (void)setAlwaysHidden:(BOOL)alwaysHidden
{
    _alwaysHidden = alwaysHidden;
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
    
    if (self.alwaysHidden) {
        self.hidden = YES;
    }
    else if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] == AVKeyValueStatusLoaded) {
        // Get available tracks. The button is only available if there are subtitles and / or audio tracks to choose from. If
        // subtitles are set, display the button in a selected state.
        AVMediaSelectionGroup *audioGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        NSArray<AVMediaSelectionOption *> *audioOptions = audioGroup.options;
        
        AVMediaSelectionGroup *subtitleGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        NSArray<AVMediaSelectionOption *> *subtitleOptions = subtitleGroup ? [AVMediaSelectionGroup mediaSelectionOptionsFromArray:subtitleGroup.srgmediaplayer_languageOptions withoutMediaCharacteristics:@[AVMediaCharacteristicContainsOnlyForcedSubtitles]] : nil;
        
        if (audioOptions.count > 1 || subtitleOptions.count != 0) {
            self.hidden = NO;
            
            // Enable the button if an (optional) subtitle has been selected
            if (subtitleGroup) {
                AVMediaSelectionOption *currentSubtitleOption = [playerItem srgmediaplayer_selectedMediaOptionInMediaSelectionGroup:subtitleGroup];
                [self.button setImage:[subtitleOptions containsObject:currentSubtitleOption] ? self.selectedImage : self.image forState:UIControlStateNormal];
            }
            else {
                [self.button setImage:self.image forState:UIControlStateNormal];
            }
        }
        else {
            self.hidden = YES;
        }
    }
    else if (self.fakeInterfaceBuilderButton) {
        self.hidden = NO;
    }
    else {
        self.hidden = YES;
    }
}

#pragma mark SRGAlternateTracksViewControllerDelegate protocol

- (void)alternateTracksViewControllerWasDismissed:(id)alternateTracksViewController
{
    if ([self.delegate respondsToSelector:@selector(tracksButtonDidHideTrackSelection:)]) {
        [self.delegate tracksButtonDidHideTrackSelection:self];
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
    if ([self.delegate respondsToSelector:@selector(tracksButtonWillShowTrackSelection:)]) {
        [self.delegate tracksButtonWillShowTrackSelection:self];
    }
    
    SRGAlternateTracksViewController *tracksViewController = [[SRGAlternateTracksViewController alloc] initWithMediaPlayerController:self.mediaPlayerController
                                                                                                                  userInterfaceStyle:self.userInterfaceStyle];
    tracksViewController.delegate = self;
    tracksViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                           target:self
                                                                                                           action:@selector(hideTracks:)];
    SRGMediaPlayerNavigationController *navigationController = [[SRGMediaPlayerNavigationController alloc] initWithRootViewController:tracksViewController];
    
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
    
    UIImage *image = [UIImage imageNamed:@"alternate_tracks" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
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
    return SRGMediaPlayerLocalizedString(@"Audio and Subtitles", @"Accessibility title of the button to display the pop over view to select audio or subtitles");
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

static void commonInit(SRGTracksButton *self)
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
