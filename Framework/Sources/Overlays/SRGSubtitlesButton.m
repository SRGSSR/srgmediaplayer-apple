//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGSubtitlesButton.h"

#import "NSBundle+SRGMediaPlayer.h"
#import "SRGAlternateTracksViewController.h"

#import <libextobjc/libextobjc.h>

static void *s_kvoContext = &s_kvoContext;

static UIImage *SRGSubtitlesButtonImage(void);
static UIImage *SRGSelectedSubtitlesButtonImage(void);

@interface SRGSubtitlesButton () <SRGAlternateTracksViewControllerDelegate>

@property (nonatomic) UIPopoverController *currentPopover;

@end

@implementation SRGSubtitlesButton

@synthesize image = _image;
@synthesize selectedImage = _selectedImage;
@synthesize alwaysVisible = _alwaysVisible;

#pragma mark Object lifecycle

- (void)dealloc
{
    self.mediaPlayerController = nil;       // Unregister KVO and notifications
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [_mediaPlayerController removeObserver:self forKeyPath:@keypath(_mediaPlayerController.player.currentItem) context:s_kvoContext];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self updateAppearanceForMediaPlayerController:mediaPlayerController];
    
    if (mediaPlayerController) {
        [mediaPlayerController addObserver:self forKeyPath:@keypath(mediaPlayerController.player.currentItem) options:0 context:s_kvoContext];
    }
}

- (UIImage *)image
{
    return _image ?: SRGSubtitlesButtonImage();
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

- (void)setAlwaysVisible:(BOOL)alwaysVisible
{
    _alwaysVisible = alwaysVisible;
    [self updateAppearance];
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self updateAppearance];
        [self addTarget:self action:@selector(showSubtitlesMenu:) forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        [self removeTarget:self action:@selector(showSubtitlesMenu:) forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark Appearance

- (void)updateAppearance
{
    [self updateAppearanceForMediaPlayerController:self.mediaPlayerController];
}

- (void)updateAppearanceForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    // Replace with custom image to be able to apply a tint color. The button color is automagically inherited from
    // the enclosing view (this works both at runtime and when rendering in Interface Builder)
    [self setImage:self.image forState:UIControlStateNormal];
    [self setImage:self.selectedImage forState:UIControlStateSelected];
    
    if (mediaPlayerController) {
        // Get available subtitles. If no one, the button disappears or disable. if one or more, display the button. If
        // one of subtitles is displayed, set the button in the selected state.
        AVPlayerItem *playerItem = mediaPlayerController.player.currentItem;
        AVMediaSelectionGroup *subtitleGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        NSArray *options = subtitleGroup.options;
        
        if (!options.count) {
            self.hidden = YES && !self.alwaysVisible;
            self.enabled = NO;
        }
        else {
            self.hidden = NO;
            self.enabled = YES;
            
            AVMediaSelectionOption *currentOption = [playerItem selectedMediaOptionInMediaSelectionGroup:subtitleGroup];
            self.selected = (currentOption != nil);
        }
    }
    else {
        self.hidden = YES && !self.alwaysVisible;
        self.enabled = NO;
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == s_kvoContext) {
        SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerController;
        if ([keyPath isEqualToString:@keypath(mediaPlayerController.player.currentItem)]) {
            [self updateAppearance];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Actions

- (IBAction)showSubtitlesMenu:(id)sender
 {
     if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad))
     {
         [self.currentPopover dismissPopoverAnimated:YES];
         self.currentPopover = nil;
         self.currentPopover = [SRGAlternateTracksViewController alternateTracksViewControllerInPopoverWithDelegate:self
                                                                                                             player:self.mediaPlayerController.player];
         [self.currentPopover presentPopoverFromRect:self.bounds
                                              inView:self
                            permittedArrowDirections:UIPopoverArrowDirectionAny
                                            animated:YES];
     }
     else {
         UINavigationController *navigationController = [SRGAlternateTracksViewController alternateTracksViewControllerInNavigationControllerWithDelegate:nil
                                                                                                                                                       player:self.mediaPlayerController.player];
         UIViewController *presentedViewController = [UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController ?:
         [UIApplication sharedApplication].delegate.window.rootViewController;
         [presentedViewController presentViewController:navigationController
                                               animated:YES
                                             completion:nil];
     }
 }

#pragma mark SRGAlternateTracksViewControllerDelegate

- (void)alternateTracksViewController:(SRGAlternateTracksViewController *)alternateTracksViewController selectedMediaOption:(AVMediaSelectionOption *)option inGroup:(AVMediaSelectionGroup *)group
{
    [self updateAppearance];
}
#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    
    [self setImage:self.image forState:UIControlStateNormal];
}

@end

#pragma mark Functions

static UIImage *SRGSubtitlesButtonImage(void)
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
