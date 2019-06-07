//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAirPlayButton.h"

#import "AVAudioSession+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "MPVolumeView+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "UIScreen+SRGMediaPlayer.h"

#import <libextobjc/libextobjc.h>

static void commonInit(SRGAirPlayButton *self);

@interface SRGAirPlayButton ()

@property (nonatomic, weak) UIButton *fakeInterfaceBuilderButton;
@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation SRGAirPlayButton

@synthesize image = _image;
@synthesize activeTintColor = _activeTintColor;

#pragma mark Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
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
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive)];
        [_mediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
        
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UIScreenDidConnectNotification
                                                    object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UIScreenDidDisconnectNotification
                                                    object:nil];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self updateAppearanceForMediaPlayerController:mediaPlayerController];
    
    if (mediaPlayerController) {
        @weakify(self)
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateAppearance];
        }];
        
        self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
            [self updateAppearance];
        }];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_airPlayButton_screenDidConnect:)
                                                   name:UIScreenDidConnectNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_airPlayButton_screenDidDisconnect:)
                                                   name:UIScreenDidDisconnectNotification
                                                 object:nil];
    }
}

- (UIImage *)image
{
    return _image ?: [UIImage imageNamed:@"airplay" inBundle:NSBundle.srg_mediaPlayerBundle compatibleWithTraitCollection:nil];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self updateAppearance];
}

- (UIColor *)activeTintColor
{
    // If none, use standard blue tint color
    return _activeTintColor ?: [UIColor colorWithRed:0.f / 255.f green:122.f / 255.f blue:255.f / 255.f alpha:1.f];
}

- (void)setActiveTintColor:(UIColor *)activeTintColor
{
    _activeTintColor = activeTintColor;
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
}

- (CGSize)intrinsicContentSize
{
    if (self.fakeInterfaceBuilderButton) {
        return self.fakeInterfaceBuilderButton.intrinsicContentSize;
    }
    else {
        return CGSizeMake(0, 0);
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
    
    if (self.alwaysHidden) {
        self.hidden = YES;
    }
    else if (mediaPlayerController) {
        BOOL allowsAirPlayPlayback = mediaPlayerController.mediaType != SRGMediaPlayerMediaTypeVideo || mediaPlayerController.allowsExternalNonMirroredPlayback;
        self.hidden = YES;
    }
    else {
        self.hidden = YES;
    }
}

#pragma mark Notifications

- (void)srg_airPlayButton_wirelessRoutesAvailableDidChange:(NSNotification *)notification
{
    [self updateAppearance];
}

- (void)srg_airPlayButton_wirelessRouteActiveDidChange:(NSNotification *)notification
{
    [self updateAppearance];
}

- (void)srg_airPlayButton_screenDidConnect:(NSNotification *)notification
{
    [self updateAppearance];
}

- (void)srg_airPlayButton_screenDidDisconnect:(NSNotification *)notification
{
    [self updateAppearance];
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    
    // Use a fake button for Interface Builder rendering, since the volume view (and thus its AirPlay button) is only
    // visible on a device
    UIButton *fakeInterfaceBuilderButton = [UIButton buttonWithType:UIButtonTypeSystem];
    fakeInterfaceBuilderButton.frame = self.bounds;
    fakeInterfaceBuilderButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    fakeInterfaceBuilderButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [fakeInterfaceBuilderButton setImage:self.image forState:UIControlStateNormal];
    [self addSubview:fakeInterfaceBuilderButton];
    self.fakeInterfaceBuilderButton = fakeInterfaceBuilderButton;
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return SRGMediaPlayerNonLocalizedString(@"AirPlay");
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

static void commonInit(SRGAirPlayButton *self)
{
    
    self.hidden = YES;
}
