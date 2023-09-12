//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGAirPlayButton.h"

#import "AVRoutePickerView+SRGMediaPlayer.h"
#import "AVAudioSession+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "SRGRouteDetector.h"
#import "UIScreen+SRGMediaPlayer.h"

@import libextobjc;

static void commonInit(SRGAirPlayButton *self);

@interface SRGAirPlayButton ()

@property (nonatomic, weak) AVRoutePickerView *routePickerView;
@property (nonatomic, weak) UIButton *fakeInterfaceBuilderButton;

@end

@implementation SRGAirPlayButton

@synthesize audioImage = _audioImage;
@synthesize videoImage = _videoImage;
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
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.player.allowsExternalPlayback)];
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.player.externalPlaybackActive)];
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive)];
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.mediaType)];
        
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
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.player.allowsExternalPlayback) options:0 block:^(MAKVONotification * _Nonnull notification) {
            @strongify(self)
            [self updateAppearance];
        }];
        
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.player.externalPlaybackActive) options:0 block:^(MAKVONotification * _Nonnull notification) {
            @strongify(self)
            [self updateAppearance];
        }];
        
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateAppearance];
        }];
        
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.mediaType) options:0 block:^(MAKVONotification * _Nonnull notification) {
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

- (void)setAudioImage:(UIImage *)audioImage
{
    _audioImage = audioImage;
    [self updateAppearance];
}

- (UIImage *)videoImage
{
    // `AVRoutePickerView`: Image is already the one we want if not specified, but was introduced with iOS 13
    if (@available(iOS 13, *)) {
        return _videoImage;
    }
    // `MPVolumeView`: Use bundled AirPlay icon when no image is specified.
    else {
        return _videoImage ?: [UIImage imageNamed:@"airplay_video" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
    }
}

- (void)setVideoImage:(UIImage *)videoImage
{
    _videoImage = videoImage;
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
    
    self.routePickerView.frame = self.bounds;
}

- (CGSize)intrinsicContentSize
{
    if (self.fakeInterfaceBuilderButton) {
        return self.fakeInterfaceBuilderButton.intrinsicContentSize;
    }
    else {
        return self.routePickerView.intrinsicContentSize;
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
    
    SRGMediaPlayerMediaType mediaType = mediaPlayerController.mediaType;
    UIImage *image = (mediaType == SRGMediaPlayerMediaTypeVideo && mediaPlayerController.player.allowsExternalPlayback) ? self.videoImage : self.audioImage;
    
    // `AVRoutePickerView` is a button with no image, with layers representing the AirPlay icon instead. If we need
    // to display an image the original icon layers needs to be hidden first.
    if (@available(iOS 13, *)) {
        self.routePickerView.prioritizesVideoDevices = (mediaType == SRGMediaPlayerMediaTypeVideo);
    }
    
    BOOL hasImage = (image != nil);
    
    airPlayButton = self.routePickerView.srg_airPlayButton;
    dispatch_async(dispatch_get_main_queue(), ^{
        airPlayButton.imageView.contentMode = hasImage ? UIViewContentModeCenter : UIViewContentModeScaleToFill;
    });

    self.routePickerView.activeTintColor = self.activeTintColor;
    self.routePickerView.srg_isOriginalIconHidden = hasImage;
    
    [airPlayButton setImage:image forState:UIControlStateNormal];
    [airPlayButton setImage:image forState:UIControlStateSelected];
    
    if (self.alwaysHidden) {
        self.hidden = YES;
    }
    else if (mediaPlayerController) {
        if (SRGRouteDetector.sharedRouteDetector.multipleRoutesDetected) {
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
    fakeInterfaceBuilderButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    UIImage *image = [UIImage imageNamed:@"airplay_audio" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
    [fakeInterfaceBuilderButton setImage:image forState:UIControlStateNormal];
    
    [self addSubview:fakeInterfaceBuilderButton];
    self.fakeInterfaceBuilderButton = fakeInterfaceBuilderButton;
    
    fakeInterfaceBuilderButton.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [fakeInterfaceBuilderButton.topAnchor constraintEqualToAnchor:self.topAnchor],
        [fakeInterfaceBuilderButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [fakeInterfaceBuilderButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [fakeInterfaceBuilderButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
    ]];
    
    self.routePickerView.hidden = YES;
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
    AVRoutePickerView *routePickerView = [[AVRoutePickerView alloc] initWithFrame:self.bounds];
    [self addSubview:routePickerView];
    self.routePickerView = routePickerView;
    
    self.hidden = YES;
}

#endif
