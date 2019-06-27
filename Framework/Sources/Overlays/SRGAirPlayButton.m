//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAirPlayButton.h"

#import "AVRoutePickerView+SRGMediaPlayer.h"
#import "AVAudioSession+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "MPVolumeView+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "SRGRouteDetector.h"
#import "UIScreen+SRGMediaPlayer.h"

#import <libextobjc/libextobjc.h>

static void commonInit(SRGAirPlayButton *self);

@interface SRGAirPlayButton ()

@property (nonatomic, weak) MPVolumeView *volumeView;
@property (nonatomic, weak) AVRoutePickerView *routePickerView API_AVAILABLE(ios(11.0));

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
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.player.externalPlaybackActive)];
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive)];
        [_mediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
        
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerWirelessRoutesAvailableDidChangeNotification
                                                    object:nil];
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
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.player.externalPlaybackActive) options:0 block:^(MAKVONotification * _Nonnull notification) {
            @strongify(self)
            [self updateAppearance];
        }];
        
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateAppearance];
        }];
        
        self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
            [self updateAppearance];
        }];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_airPlayButton_wirelessRoutesAvailableDidChange:)
                                                   name:SRGMediaPlayerWirelessRoutesAvailableDidChangeNotification
                                                 object:nil];
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
    // `AVRoutePickerView`: Image is already the one we want if not specified (AirPlay audio)
    if (@available(iOS 11, *)) {
        return _image;
    }
    // `MPVolumeView`: Use bundled AirPlay audio icon when no image is specified.
    else {
        return _image ?: [UIImage imageNamed:@"airplay" inBundle:NSBundle.srg_mediaPlayerBundle compatibleWithTraitCollection:nil];
    }
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self updateAppearance];
}

- (UIColor *)activeTintColor
{
    // Use standard blue tint color as default
    return _activeTintColor ?: [UIColor colorWithRed:0.3629f green:0.7041f blue:1.f alpha:1.f];
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
    
    if (@available(iOS 11, *)) {
        self.routePickerView.frame = self.bounds;
    }
    else {
        // Ensure proper resizing behavior of the volume view AirPlay button.
        self.volumeView.frame = self.bounds;
        
        UIButton *airPlayButton = self.volumeView.srg_airPlayButton;
        airPlayButton.frame = self.volumeView.bounds;
    }
}

- (CGSize)intrinsicContentSize
{
    if (self.fakeInterfaceBuilderButton) {
        return self.fakeInterfaceBuilderButton.intrinsicContentSize;
    }
    else {
        return self.volumeView.srg_airPlayButton.intrinsicContentSize;
    }
}

#pragma mark Appearance

- (void)updateAppearance
{
    [self updateAppearanceForMediaPlayerController:self.mediaPlayerController];
}

- (void)updateAppearanceForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    UIButton *airPlayButton = nil;
    
    // `AVRoutePickerView` is a button with no image, with layers representing the AirPlay icon instead. If we need
    // to display an image the original icon layers needs to be hidden first.
    if (@available(iOS 11, *)) {
        BOOL hasImage = (self.image != nil);
        
        airPlayButton = self.routePickerView.srg_airPlayButton;
        airPlayButton.imageView.contentMode = hasImage ? UIViewContentModeCenter : UIViewContentModeScaleToFill;
        
        self.routePickerView.activeTintColor = self.activeTintColor;
        self.routePickerView.srg_isOriginalIconHidden = hasImage;
    }
    // For `MPVolumeView` we must use a custom image to be able to apply a tint color. The button color is automagically
    // inherited from the enclosing view (this works both at runtime and when rendering in Interface Builder)
    else {
        airPlayButton = self.volumeView.srg_airPlayButton;
        airPlayButton.showsTouchWhenHighlighted = NO;
        airPlayButton.tintColor = AVAudioSession.srg_isAirPlayActive ? self.activeTintColor : self.tintColor;
    }
    
    [airPlayButton setImage:self.image forState:UIControlStateNormal];
    [airPlayButton setImage:self.image forState:UIControlStateSelected];
    
    if (self.alwaysHidden) {
        self.hidden = YES;
    }
    else if (mediaPlayerController) {
        BOOL allowsAirPlayPlayback = mediaPlayerController.mediaType == SRGMediaPlayerMediaTypeAudio || mediaPlayerController.allowsExternalNonMirroredPlayback;
        if (SRGRouteDetector.sharedRouteDetector.multipleRoutesDetected && allowsAirPlayPlayback) {
            self.hidden = NO;
        }
        else {
            self.hidden = YES;
        }
    }
    else {
        self.hidden = ! self.fakeInterfaceBuilderButton && ! SRGRouteDetector.sharedRouteDetector.multipleRoutesDetected;
    }
}

#pragma mark Notifications

- (void)srg_airPlayButton_wirelessRoutesAvailableDidChange:(NSNotification *)notification
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
    if (@available(iOS 11, *)) {
        AVRoutePickerView *routePickerView = [[AVRoutePickerView alloc] initWithFrame:self.bounds];
        [self addSubview:routePickerView];
        self.routePickerView = routePickerView;
    }
    else {
        MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:self.bounds];
        volumeView.showsVolumeSlider = NO;
        [self addSubview:volumeView];
        self.volumeView = volumeView;
    }
    self.hidden = YES;
}
