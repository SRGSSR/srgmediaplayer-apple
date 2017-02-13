//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAirplayButton.h"

#import "AVAudioSession+SRGMediaPlayer.h"
#import "MPVolumeView+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "UIScreen+SRGMediaPlayer.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

static UIImage *SRGAirplayButtonImage(void);

static void commonInit(SRGAirplayButton *self);

@interface SRGAirplayButton ()

@property (nonatomic, weak) MPVolumeView *volumeView;
@property (nonatomic, weak) UIButton *fakeInterfaceBuilderButton;

@end

@implementation SRGAirplayButton

@synthesize image = _image;
@synthesize activeTintColor = _activeTintColor;
@synthesize alwaysHidden = _alwaysHidden;

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
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPVolumeViewWirelessRouteActiveDidChangeNotification
                                                      object:self.volumeView];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification
                                                      object:self.volumeView];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIScreenDidConnectNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIScreenDidDisconnectNotification
                                                      object:nil];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self updateAppearanceForMediaPlayerController:mediaPlayerController];
    
    if (mediaPlayerController) {
        @weakify(self)
        [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateAppearance];
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_airplayButton_wirelessRouteActiveDidChange:)
                                                     name:MPVolumeViewWirelessRouteActiveDidChangeNotification
                                                   object:self.volumeView];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_airplayButton_wirelessRoutesAvailableDidChange:)
                                                     name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification
                                                   object:self.volumeView];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_airplayButton_screenDidConnect:)
                                                     name:UIScreenDidConnectNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_airplayButton_screenDidDisconnect:)
                                                     name:UIScreenDidDisconnectNotification
                                                   object:nil];
    }
}

- (UIImage *)image
{
    return _image ?: SRGAirplayButtonImage();
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

- (CGSize)intrinsicContentSize
{
    if (self.fakeInterfaceBuilderButton) {
        return self.fakeInterfaceBuilderButton.intrinsicContentSize;
    }
    else {
        return super.intrinsicContentSize;
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
    UIButton *airplayButton = self.volumeView.srg_airplayButton;
    airplayButton.showsTouchWhenHighlighted = NO;
    [airplayButton setImage:self.image forState:UIControlStateNormal];
    [airplayButton setImage:self.image forState:UIControlStateSelected];
    
    if (self.alwaysHidden) {
        self.hidden = YES;
    }
    else if (mediaPlayerController) {
        // True Airplay active. Use Airplay availability status
        if (mediaPlayerController.allowsExternalNonMirroredPlayback && self.volumeView.areWirelessRoutesAvailable) {
            airplayButton.tintColor = [AVAudioSession srg_isAirplayActive] ? self.activeTintColor : self.tintColor;
            self.hidden = NO;
        }
        else {
            self.hidden = YES;
        }
    }
    else {
        self.hidden = ! self.fakeInterfaceBuilderButton && ! self.volumeView.areWirelessRoutesAvailable;
    }
}

#pragma mark Notifications

- (void)srg_airplayButton_wirelessRoutesAvailableDidChange:(NSNotification *)notification
{
    [self updateAppearance];
}

- (void)srg_airplayButton_wirelessRouteActiveDidChange:(NSNotification *)notification
{
    [self updateAppearance];
}

- (void)srg_airplayButton_screenDidConnect:(NSNotification *)notification
{
    [self updateAppearance];
}

- (void)srg_airplayButton_screenDidDisconnect:(NSNotification *)notification
{
    [self updateAppearance];
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    
    // Use a fake button for Interface Builder rendering, since the volume view (and thus its Airplay button) is only
    // visible on a device
    UIButton *fakeInterfaceBuilderButton = [UIButton buttonWithType:UIButtonTypeSystem];
    fakeInterfaceBuilderButton.frame = self.bounds;
    fakeInterfaceBuilderButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [fakeInterfaceBuilderButton setImage:self.image forState:UIControlStateNormal];
    [self addSubview:fakeInterfaceBuilderButton];
    self.fakeInterfaceBuilderButton = fakeInterfaceBuilderButton;
}

@end

#pragma mark Functions

static UIImage *SRGAirplayButtonImage(void)
{
    static UIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *imagePath = [[NSBundle srg_mediaPlayerBundle] pathForResource:@"airplay" ofType:@"png"];
        image = [[UIImage imageWithContentsOfFile:imagePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

static void commonInit(SRGAirplayButton *self)
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:self.bounds];
    volumeView.showsVolumeSlider = NO;
    volumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:volumeView];
    self.volumeView = volumeView;
    
    self.hidden = YES;
}
