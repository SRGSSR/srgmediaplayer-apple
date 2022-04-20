//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGPictureInPictureButton.h"

#import "NSBundle+SRGMediaPlayer.h"
#import "SRGMediaPlayerController.h"

static void commonInit(SRGPictureInPictureButton *self);

@interface SRGPictureInPictureButton ()

@property (nonatomic, weak) UIButton *button;
@property (nonatomic, weak) UIButton *fakeInterfaceBuilderButton;

@end

@implementation SRGPictureInPictureButton

@synthesize startImage = _startImage;
@synthesize stopImage = _stopImage;

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
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                    object:_mediaPlayerController];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerPictureInPictureStateDidChangeNotification
                                                    object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self updateAppearanceForMediaPlayerController:mediaPlayerController];
    
    if (mediaPlayerController) {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_pictureInPictureButton_playbackStateDidChange:)
                                                   name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                 object:mediaPlayerController];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_pictureInPictureButton_pictureInPictureStateDidChange:)
                                                   name:SRGMediaPlayerPictureInPictureStateDidChangeNotification
                                                 object:mediaPlayerController];
    }
}

- (UIImage *)startImage
{
    return _startImage ?: [UIImage imageNamed:@"picture_in_picture_start" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
}

- (void)setStartImage:(UIImage *)startImage
{
    _startImage = startImage;
    [self updateAppearance];
}

- (UIImage *)stopImage
{
    return _stopImage ?: [UIImage imageNamed:@"picture_in_picture_stop" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
}

- (void)setStopImage:(UIImage *)stopImage
{
    _stopImage = stopImage;
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
    return [self updateAppearanceForMediaPlayerController:self.mediaPlayerController];
}

- (void)updateAppearanceForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    AVPictureInPictureController *pictureInPictureController = mediaPlayerController.pictureInPictureController;
    
    if (self.alwaysHidden) {
        self.hidden = YES;
    }
    else if (pictureInPictureController.pictureInPicturePossible
             && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle
             && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePreparing
             && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded) {
        self.hidden = NO;
        
        UIImage *image = pictureInPictureController.pictureInPictureActive ? self.stopImage : self.startImage;
        [self.button setImage:image forState:UIControlStateNormal];
    }
    else if (self.fakeInterfaceBuilderButton) {
        self.hidden = NO;
    }
    else {
        self.hidden = YES;
    }
}

#pragma mark Actions

- (void)srg_pictureInPictureButton_togglePictureInPicture:(id)sender
{
    AVPictureInPictureController *pictureInPictureController = self.mediaPlayerController.pictureInPictureController;
    
    if (! pictureInPictureController.pictureInPicturePossible) {
        return;
    }
    
    if (pictureInPictureController.pictureInPictureActive) {
        [pictureInPictureController stopPictureInPicture];
    }
    else {
        [pictureInPictureController startPictureInPicture];
    }
}

#pragma mark Notifications

- (void)srg_pictureInPictureButton_playbackStateDidChange:(NSNotification *)notification
{
    [self updateAppearance];
}

- (void)srg_pictureInPictureButton_pictureInPictureStateDidChange:(NSNotification *)notification
{
    [self updateAppearance];
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
    fakeInterfaceBuilderButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    UIImage *image = [UIImage imageNamed:@"picture_in_picture_start" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
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
    AVPictureInPictureController *pictureInPictureController = self.mediaPlayerController.pictureInPictureController;
    
    if (pictureInPictureController.pictureInPictureActive) {
        return SRGMediaPlayerAccessibilityLocalizedString(@"Stop Picture in Picture", @"Picture In Picture button label, when PiP is active");
    }
    else {
        return SRGMediaPlayerAccessibilityLocalizedString(@"Start Picture in Picture", @"Picture In Picture button label, when PiP is available");
    }
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

static void commonInit(SRGPictureInPictureButton *self)
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [button addTarget:self action:@selector(srg_pictureInPictureButton_togglePictureInPicture:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    self.button = button;
    
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [button.topAnchor constraintEqualToAnchor:self.topAnchor],
        [button.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [button.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [button.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
    ]];
    
    self.hidden = YES;
}

#endif
