//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGTracksButton.h"

#import "AVAudioSession+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "SRGAlternateTracksViewController.h"
#import "UIWindow+SRGMediaPlayer.h"

#import <libextobjc/libextobjc.h>

static void commonInit(SRGTracksButton *self);

@interface SRGTracksButton ()

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
        NSArray<AVMediaSelectionOption *> *subtitleOptions = subtitleGroup.options;
        
        if (audioOptions.count > 1 || subtitleOptions.count != 0) {
            self.hidden = NO;
            self.button.enabled = YES;
            
            // Enable the button if an (optional) subtitle has been selected (an audio track is always selected)
            AVMediaSelectionOption *currentSubtitleOption = [playerItem selectedMediaOptionInMediaSelectionGroup:subtitleGroup];
            self.button.selected = (currentSubtitleOption != nil);
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

#pragma mark UIPopoverPresentationControllerDelegate protocol

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
    if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        return UIModalPresentationOverFullScreen;
    }
    else {
        return UIModalPresentationPopover;
    }
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    if ([self.delegate respondsToSelector:@selector(tracksButtonDidHideSelectionPopover:)]) {
        [self.delegate tracksButtonDidHideSelectionPopover:self];
    }
}

#pragma mark Actions

- (void)showSubtitlesMenu:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(tracksButtonWillShowSelectionPopover:)]) {
        [self.delegate tracksButtonWillShowSelectionPopover:self];
    }
    
    UINavigationController *navigationController = [SRGAlternateTracksViewController alternateTracksNavigationControllerForMediaPlayerController:self.mediaPlayerController
                                                                                                                          withUserInterfaceStyle:self.userInterfaceStyle];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navigationController.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popoverPresentationController = navigationController.popoverPresentationController;
        popoverPresentationController.delegate = self;
        popoverPresentationController.sourceView = self;
        popoverPresentationController.sourceRect = self.bounds;
    }
    else if (@available(iOS 13, *)) {
        // Default behavior leads to expected result
    }
    else {
        // UIModalPresentationFullScreen is required if we want the presented view controller to control the status
        // bar appearance
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
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
    [button addTarget:self action:@selector(showSubtitlesMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    self.button = button;
    
    self.hidden = YES;
}
