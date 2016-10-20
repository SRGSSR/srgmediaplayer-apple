//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAirplayButton.h"

#import "MPVolumeView+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"

#import <libextobjc/libextobjc.h>

static void *s_kvoContext = &s_kvoContext;

static UIImage *SRGAirplayButtonImage(void);

static void commonInit(SRGAirplayButton *self);

@interface SRGAirplayButton ()

@property (nonatomic, weak) MPVolumeView *volumeView;
@property (nonatomic, weak) UIButton *fakeInterfaceBuilderButton;

@end

@implementation SRGAirplayButton

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
    self.mediaPlayerController = nil;       // Unregister KVO and notifications
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [_mediaPlayerController removeObserver:self forKeyPath:@keypath(_mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) context:s_kvoContext];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPVolumeViewWirelessRouteActiveDidChangeNotification
                                                      object:self.volumeView];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification
                                                      object:self.volumeView];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self updateAppearanceForMediaPlayerController:mediaPlayerController];
    
    if (mediaPlayerController) {
        [mediaPlayerController addObserver:self forKeyPath:@keypath(mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) options:0 context:s_kvoContext];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_airplayButton_wirelessRouteActiveDidChange:)
                                                     name:MPVolumeViewWirelessRouteActiveDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_airplayButton_wirelessRoutesAvailableDidChange:)
                                                     name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification
                                                   object:self.volumeView];
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
    return _activeTintColor ?: [UIColor blueColor];
}

- (void)setActiveTintColor:(UIColor *)activeTintColor
{
    _activeTintColor = activeTintColor;
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
    
    if (mediaPlayerController) {
        // Determine whether Airplay is active or not
        if (mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) {
            AVAudioSession *audioSession = [AVAudioSession sharedInstance];
            AVAudioSessionRouteDescription *currentRoute = audioSession.currentRoute;
            
            BOOL active = YES;
            for (AVAudioSessionPortDescription *outputPort in currentRoute.outputs) {
                if ([outputPort.portType isEqualToString:AVAudioSessionPortAirPlay]) {
                    active = NO;
                    break;
                }
            }
            
            airplayButton.tintColor = active ? self.tintColor : self.activeTintColor;
            self.hidden = NO;
        }
        // Mirroring. Hide the button
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

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == s_kvoContext) {
        SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerController;
        if ([keyPath isEqualToString:@keypath(mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive)]) {
            [self updateAppearance];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
}
