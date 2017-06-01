//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPlaybackButton.h"

#import "SRGMediaPlayerIconTemplate.h"
#import "NSBundle+SRGMediaPlayer.h"

#import <libextobjc/libextobjc.h>

@interface SRGPlaybackButton ()

@property (nonatomic) UIColor *normalTintColor;

@property (weak) id periodicTimeObserver;

@end

@implementation SRGPlaybackButton

@synthesize playImage = _playImage;
@synthesize pauseImage = _pauseImage;
@synthesize highlightedTintColor = _highlightedTintColor;
@synthesize playImageAccessibilityLabel = _playImageAccessibilityLabel;
@synthesize pauseImageAccessibilityLabel = _pauseImageAccessibilityLabel;

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
        [_mediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                      object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self refreshButton];
    
    if (mediaPlayerController) {
        @weakify(self)
        self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
            
            [self refreshButton];
        }];
        [[NSNotificationCenter defaultCenter] addObserver:self
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

- (UIColor *)highlightedTintColor
{
    return _highlightedTintColor ?: self.tintColor;
}

- (NSString *)playImageAccessibilityLabel
{
    return _playImageAccessibilityLabel ?: SRGMediaPlayerAccessibilityLocalizedString(@"Play", @"Play state of the Play/Pause button");
}

- (void)setPlayImageAccessibilityLabel:(NSString *)playImageAccessibilityLabel
{
    _playImageAccessibilityLabel = playImageAccessibilityLabel;
    [self refreshButton];
}

- (NSString *)pauseImageAccessibilityLabel
{
    return  _pauseImageAccessibilityLabel ?: SRGMediaPlayerAccessibilityLocalizedString(@"Pause", @"Pause state of the Play/Pause button");
}

- (void)setPauseImageAccessibilityLabel:(NSString *)pauseImageAccessibilityLabel
{
    _pauseImageAccessibilityLabel = pauseImageAccessibilityLabel;
    [self refreshButton];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self refreshButton];
}

#pragma mark UI

- (void)refreshButton
{
    [self removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(togglePlayPause:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage *normalImage = nil;
    UIImage *highlightedImage = nil;
    NSString *accessibilityLabel = nil;
 
    BOOL displaysInterruptionButton = (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying
                                        || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateSeeking
                                        || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateStalled);
    
    if (displaysInterruptionButton) {
        normalImage = self.pauseImage;
        highlightedImage = self.pauseImage;
        accessibilityLabel = self.pauseImageAccessibilityLabel;
    }
    else {
        normalImage = self.playImage;
        highlightedImage = self.playImage;
        accessibilityLabel = self.playImageAccessibilityLabel;
    }
    
    [self setImage:normalImage forState:UIControlStateNormal];
    [self setImage:highlightedImage forState:UIControlStateHighlighted];
    self.accessibilityLabel = accessibilityLabel;
}

#pragma mark Actions

- (void)togglePlayPause:(id)sender
{
    [self.mediaPlayerController togglePlayPause];
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

@end
