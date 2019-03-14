//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGTracksButton.h"

#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "SRGAlternateTracksViewController.h"
#import "UIWindow+SRGMediaPlayer.h"

#import <libextobjc/libextobjc.h>

static void commonInit(SRGTracksButton *self);

@interface SRGTracksButton () <SRGAlternateTracksViewControllerDelegate>

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
    [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.playbackState)];
    
    _mediaPlayerController = mediaPlayerController;
    [self updateAppearanceForMediaPlayerController:mediaPlayerController];
    
    if (mediaPlayerController) {
        @weakify(self)
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.playbackState) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateAppearance];
        }];
    }
}

- (UIImage *)image
{
    return _image ?: [UIImage imageNamed:@"alternate_tracks_button" inBundle:NSBundle.srg_mediaPlayerBundle compatibleWithTraitCollection:nil];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self updateAppearance];
}

- (UIImage *)selectedImage
{
    return _selectedImage ?: [UIImage imageNamed:@"alternate_tracks_button_selected" inBundle:NSBundle.srg_mediaPlayerBundle compatibleWithTraitCollection:nil];
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
    [self.button setImage:self.image forState:UIControlStateNormal];
    [self.button setImage:self.selectedImage forState:UIControlStateSelected];
    
    AVPlayerItem *playerItem = mediaPlayerController.player.currentItem;
    
    if (self.alwaysHidden) {
        self.hidden = YES;
    }
    // Do not check tracks before the player item is ready to play (otherwise AVPlayer will internally wait on semaphores,
    // locking the main thread).
    else if (playerItem && playerItem.status == AVPlayerItemStatusReadyToPlay) {
        // Get available subtitles. If no one, the button disappears or disable. if one or more, display the button. If
        // one of subtitles is displayed, set the button in the selected state.
        AVMediaSelectionGroup *legibleGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        NSArray<AVMediaSelectionOption *> *legibleOptions = legibleGroup.options;
        
        AVMediaSelectionGroup *audibleGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        NSArray<AVMediaSelectionOption *> *audibleOptions = audibleGroup.options;
        
        if (legibleOptions.count != 0 || audibleOptions.count > 1) {
            self.hidden = NO;
            self.button.enabled = YES;
            
            // Enable the button if an (optional) subtitle has been selected (an audio track is always selected)
            AVMediaSelectionOption *currentLegibleOption = [playerItem selectedMediaOptionInMediaSelectionGroup:legibleGroup];
            self.button.selected = (currentLegibleOption != nil);
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

- (void)alternateTracksViewControllerDidSelectMediaOption:(SRGAlternateTracksViewController *)alternateTracksViewController
{
    [self updateAppearance];
}

#pragma mark UIPopoverPresentationControllerDelegate protocol

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Needed for the iPhone
    return UIModalPresentationNone;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    if ([self.delegate respondsToSelector:@selector(tracksButtonDidHideSelectionPopopver:)]) {
        [self.delegate tracksButtonDidHideSelectionPopopver:self];
    }
}

#pragma mark Actions

- (void)showSubtitlesMenu:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(tracksButtonWillShowSelectionPopopver:)]) {
        [self.delegate tracksButtonWillShowSelectionPopopver:self];
    }
    
    UINavigationController *navigationController = [SRGAlternateTracksViewController alternateTracksNavigationControllerForPlayer:self.mediaPlayerController.player
                                                                                                                     withDelegate:self];
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    
    navigationController.popoverPresentationController.delegate = self;
    navigationController.popoverPresentationController.sourceView = self;
    navigationController.popoverPresentationController.sourceRect = self.bounds;
    
    UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.srg_topViewController;
    [topViewController presentViewController:navigationController
                                    animated:YES
                                  completion:nil];
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
    [fakeInterfaceBuilderButton setImage:self.image forState:UIControlStateNormal];
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

@end

#pragma mark Functions

static void commonInit(SRGTracksButton *self)
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = self.bounds;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    button.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [button addTarget:self action:@selector(showSubtitlesMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    self.button = button;
    
    self.hidden = YES;
}
