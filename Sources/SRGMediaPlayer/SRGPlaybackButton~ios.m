//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGPlaybackButton.h"

#import "NSBundle+SRGMediaPlayer.h"
#import "SRGMediaPlayerIconTemplate.h"

@import libextobjc;

static void commonInit(SRGPlaybackButton *self);

@interface SRGPlaybackButton ()

@property (nonatomic) SRGPlaybackButtonState playbackButtonState;

@property (nonatomic) UIColor *normalTintColor;

@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation SRGPlaybackButton

@synthesize playImage = _playImage;
@synthesize pauseImage = _pauseImage;
@synthesize highlightedTintColor = _highlightedTintColor;
@synthesize playbackButtonState = _playbackButtonState;

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

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        self.normalTintColor = self.tintColor;
        [self refreshButton];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        [super setTintColor:self.highlightedTintColor];
    }
    else {
        [super setTintColor:self.normalTintColor];
    }
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    
    self.normalTintColor = tintColor;
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                    object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self refreshButton];
    
    if (mediaPlayerController) {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(mediaPlayerPlaybackStateDidChange:)
                                                   name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                 object:mediaPlayerController];
    }
}

- (UIImage *)playImage
{
    return _playImage ?: [SRGMediaPlayerIconTemplate playImageWithSize:self.bounds.size];
}

- (void)setPlayImage:(UIImage *)playImage
{
    _playImage = playImage;
    [self refreshButton];
}

- (UIImage *)pauseImage
{
    return _pauseImage ?: [SRGMediaPlayerIconTemplate pauseImageWithSize:self.bounds.size];
}

- (void)setPauseImage:(UIImage *)pauseImage
{
    _pauseImage = pauseImage;
    [self refreshButton];
}

- (void)setHighlightedTintColor:(UIColor *)highlightedTintColor
{
    _highlightedTintColor = highlightedTintColor;
    [self refreshButton];
}

- (void)setPlaybackButtonState:(SRGPlaybackButtonState)playbackButtonState
{
    _playbackButtonState = playbackButtonState;
    
    UIImage *normalImage = nil;
    UIImage *highlightedImage = nil;
    
    if (playbackButtonState == SRGPlaybackButtonStatePause) {
        normalImage = self.pauseImage;
        highlightedImage = self.pauseImage;
    }
    else {
        normalImage = self.playImage;
        highlightedImage = self.playImage;
    }
    
    [self setImage:normalImage forState:UIControlStateNormal];
    [self setImage:highlightedImage forState:UIControlStateHighlighted];
}

- (UIColor *)highlightedTintColor
{
    return _highlightedTintColor ?: self.tintColor;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self refreshButton];
}

// Override to prevent setting a title. This fixes a nasty compiler issue when previewing in Interface Builder (eating
// up all system memory) and at runtime
- (void)setTitle:(NSString *)title forState:(UIControlState)state
{}

#pragma mark UI

- (void)refreshButton
{
    if (self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateSeeking) {
        self.playbackButtonState = (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying
                                        || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateStalled) ? SRGPlaybackButtonStatePause : SRGPlaybackButtonStatePlay;
    }
}

#pragma mark Actions

- (void)togglePlayPause:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(playbackButton:didPressInState:)]) {
        [self.delegate playbackButton:self didPressInState:self.playbackButtonState];
    }
    else {
        [self.mediaPlayerController togglePlayPause];
    }
}

#pragma mark Notifications

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
    [self refreshButton];
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    
    [self setImage:self.playImage forState:UIControlStateNormal];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    if ([self.delegate respondsToSelector:@selector(playbackButton:accessibilityLabelForState:)]) {
        NSString *accessibilityLabel = [self.delegate playbackButton:self accessibilityLabelForState:self.playbackButtonState];
        if (accessibilityLabel) {
            return accessibilityLabel;
        }
    }
    
    return (self.playbackButtonState == SRGPlaybackButtonStatePause) ? SRGMediaPlayerAccessibilityLocalizedString(@"Pause", @"Pause label of the Play/Pause button") : SRGMediaPlayerAccessibilityLocalizedString(@"Play", @"Play label of the Play/Pause button");
}

@end

#pragma mark Functions

static void commonInit(SRGPlaybackButton *self)
{
    [self addTarget:self action:@selector(togglePlayPause:) forControlEvents:UIControlEventTouchUpInside];
}

#endif
