//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGViewModeButton.h"

#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"

@import libextobjc;
@import MAKVONotificationCenter;

static void commonInit(SRGViewModeButton *self);

@interface SRGViewModeButton ()

@property (nonatomic, weak) UIButton *button;
@property (nonatomic, weak) UIButton *fakeInterfaceBuilderButton;

@end

@implementation SRGViewModeButton

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
    self.mediaPlayerView = nil;     // Unregister everything
}

#pragma mark Getters and setters

- (void)setMediaPlayerView:(SRGMediaPlayerView *)mediaPlayerView
{
    [_mediaPlayerView removeObserver:self keyPath:@keypath(_mediaPlayerView.viewMode)];
    
    _mediaPlayerView = mediaPlayerView;
    [self updateAppearanceForMediaPlayerView:mediaPlayerView];
    
    if (mediaPlayerView) {
        @weakify(self)
        [mediaPlayerView srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerView.viewMode) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateAppearance];
        }];
    }
}

- (UIImage *)viewModeMonoscopicImage
{
    return _viewModeMonoscopicImage ?: [UIImage imageNamed:@"view_mode_monoscopic" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
}

- (UIImage *)viewModeStereoscopicImage
{
    return _viewModeStereoscopicImage ?: [UIImage imageNamed:@"view_mode_stereoscopic" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
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
    return [self updateAppearanceForMediaPlayerView:self.mediaPlayerView];
}

- (void)updateAppearanceForMediaPlayerView:(SRGMediaPlayerView *)mediaPlayerView
{
    if (self.alwaysHidden) {
        self.hidden = YES;
    }
    else if (mediaPlayerView.viewMode == SRGMediaPlayerViewModeMonoscopic) {
        [self.button setImage:self.viewModeStereoscopicImage forState:UIControlStateNormal];
        self.hidden = NO;
    }
    else if (mediaPlayerView.viewMode == SRGMediaPlayerViewModeStereoscopic) {
        [self.button setImage:self.viewModeMonoscopicImage forState:UIControlStateNormal];
        self.hidden = NO;
        
    }
    else if (self.fakeInterfaceBuilderButton) {
        self.hidden = NO;
    }
    else {
        self.hidden = YES;
    }
}

#pragma mark Actions

- (void)srg_viewModeButton_toggleViewMode:(id)sender
{
    if (self.mediaPlayerView.viewMode == SRGMediaPlayerViewModeMonoscopic) {
        self.mediaPlayerView.viewMode = SRGMediaPlayerViewModeStereoscopic;
    }
    else if (self.mediaPlayerView.viewMode == SRGMediaPlayerViewModeStereoscopic) {
        self.mediaPlayerView.viewMode = SRGMediaPlayerViewModeMonoscopic;
    }
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    // See comment in `-[SRGPictureInPictureButton prepareForInterfaceBuilder]`
    UIButton *fakeInterfaceBuilderButton = [UIButton buttonWithType:UIButtonTypeSystem];
    fakeInterfaceBuilderButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [fakeInterfaceBuilderButton setImage:self.viewModeMonoscopicImage forState:UIControlStateNormal];
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
    switch (self.mediaPlayerView.viewMode) {
        case SRGMediaPlayerViewModeMonoscopic: {
            return SRGMediaPlayerAccessibilityLocalizedString(@"Headset", @"Button label to enable 360° video playback with a VR headset");
            break;
        }
            
        case SRGMediaPlayerViewModeStereoscopic: {
            return SRGMediaPlayerAccessibilityLocalizedString(@"360 degrees", @"Button label to enable 360° video playback");
            break;
        }
            
        default: {
            return nil;
            break;
        }
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

static void commonInit(SRGViewModeButton *self)
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [button addTarget:self action:@selector(srg_viewModeButton_toggleViewMode:) forControlEvents:UIControlEventTouchUpInside];
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
