//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGTracksButton.h"

#import "NSBundle+SRGMediaPlayer.h"
#import "SRGAlternateTracksViewController.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

static void commonInit(SRGTracksButton *self);

static UIImage *SRGTracksButtonImage(void);
static UIImage *SRGSelectedSubtitlesButtonImage(void);

@interface SRGTracksButton () <SRGAlternateTracksViewControllerDelegate>

@property (nonatomic, weak) UIButton *button;
@property (nonatomic, weak) UIButton *fakeInterfaceBuilderButton;

@end

@implementation SRGTracksButton

@synthesize image = _image;
@synthesize selectedImage = _selectedImage;
@synthesize alwaysHidden = _alwaysHidden;

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
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self updateAppearanceForMediaPlayerController:mediaPlayerController];
    
    if (mediaPlayerController) {
        @weakify(self)
        [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.playbackState) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateAppearance];
        }];
    }
}

- (UIImage *)image
{
    return _image ?: SRGTracksButtonImage();
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self updateAppearance];
}

- (UIImage *)selectedImage
{
    return _selectedImage ?: SRGSelectedSubtitlesButtonImage();
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
        return super.intrinsicContentSize;
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
    
    if (self.alwaysHidden) {
        self.hidden = YES;
    }
    else if (mediaPlayerController) {
        // Get available subtitles. If no one, the button disappears or disable. if one or more, display the button. If
        // one of subtitles is displayed, set the button in the selected state.
        AVPlayerItem *playerItem = mediaPlayerController.player.currentItem;
        
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

- (void)alternateTracksViewController:(SRGAlternateTracksViewController *)alternateTracksViewController didSelectMediaOption:(AVMediaSelectionOption *)option inGroup:(AVMediaSelectionGroup *)group
{
    [self updateAppearance];
    
    UIViewController *presentedViewController = [UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController ?: [UIApplication sharedApplication].delegate.window.rootViewController;
    [presentedViewController.presentedViewController dismissViewControllerAnimated:YES
                                                                        completion:nil];
}

#pragma mark UIPopoverPresentationControllerDelegate protocol

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Needed for the iPhone
    return UIModalPresentationNone;
}

#pragma mark Actions

- (void)showSubtitlesMenu:(id)sender
{
    UINavigationController *navigationController = [SRGAlternateTracksViewController alternateTracksViewControllerInNavigationControllerForPlayer:self.mediaPlayerController.player
                                                                                                                                         delegate:self];
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    
    navigationController.popoverPresentationController.delegate = self;
    navigationController.popoverPresentationController.sourceView = self;
    navigationController.popoverPresentationController.sourceRect = self.bounds;
    
    UIViewController *presentedViewController = [UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController ?: [UIApplication sharedApplication].delegate.window.rootViewController;
    [presentedViewController presentViewController:navigationController
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
    [fakeInterfaceBuilderButton setImage:self.image forState:UIControlStateNormal];
    [self addSubview:fakeInterfaceBuilderButton];
    self.fakeInterfaceBuilderButton = fakeInterfaceBuilderButton;
    
    // Hide the normal button
    self.button.hidden = YES;
}

@end

#pragma mark Functions

static void commonInit(SRGTracksButton *self)
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = self.bounds;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [button addTarget:self action:@selector(showSubtitlesMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    self.button = button;
    
    self.hidden = YES;
}

static UIImage *SRGTracksButtonImage(void)
{
    static UIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *imagePath = [[NSBundle srg_mediaPlayerBundle] pathForResource:@"alternate_tracks_button" ofType:@"png"];
        image = [[UIImage imageWithContentsOfFile:imagePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

static UIImage *SRGSelectedSubtitlesButtonImage(void)
{
    static UIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *imagePath = [[NSBundle srg_mediaPlayerBundle] pathForResource:@"alternate_tracks_button_selected" ofType:@"png"];
        image = [[UIImage imageWithContentsOfFile:imagePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}
