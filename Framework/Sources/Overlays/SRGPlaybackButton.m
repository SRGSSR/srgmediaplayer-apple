//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPlaybackButton.h"

#import "SRGMediaPlayerIconTemplate.h"

@implementation SRGPlaybackButton

#pragma mark Object lifecycle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self refreshButton];
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                      object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self refreshButton];
    
    if (mediaPlayerController) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaPlayerPlaybackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:mediaPlayerController];
    }
}

- (void)setPlayImage:(UIImage *)playImage
{
    _playImage = playImage;
    [self refreshButton];
}

- (void)setPauseImage:(UIImage *)pauseImage
{
    _pauseImage = pauseImage;
    [self refreshButton];
}

- (void)setStopImage:(UIImage *)stopImage
{
    _stopImage = stopImage;
    [self refreshButton];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self refreshButton];
}

- (void)setNormalColor:(UIColor *)normalColor
{
    _normalColor = normalColor;
    [self refreshButton];
}

- (void)setHightlightColor:(UIColor *)hightlightColor
{
    _hightlightColor = hightlightColor;
    [self refreshButton];
}

#pragma mark UI

- (void)refreshButton
{
    BOOL isPlaying = self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    
    [self removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(togglePlayPause:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage *normalImage = nil;
    UIImage *highlightedImage = nil;
    if (isPlaying) {
        normalImage = self.pauseImage ?: [SRGMediaPlayerIconTemplate pauseImageWithSize:self.bounds.size color:self.normalColor];
        highlightedImage = self.pauseImage ?: [SRGMediaPlayerIconTemplate pauseImageWithSize:self.bounds.size color:self.hightlightColor];
    }
    else {
        normalImage = self.playImage ?: [SRGMediaPlayerIconTemplate playImageWithSize:self.bounds.size color:self.normalColor];
        highlightedImage = self.playImage ?: [SRGMediaPlayerIconTemplate playImageWithSize:self.bounds.size color:self.hightlightColor];
    }
    [self setImage:normalImage forState:UIControlStateNormal];
    [self setImage:highlightedImage forState:UIControlStateHighlighted];
}

#pragma mark Actions

- (void)togglePlayPause:(id)sender
{
    void (^togglePlayPause)(void) = ^{
        [self.mediaPlayerController togglePlayPause];
        [self refreshButton];
    };
    
    if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
        [self.mediaPlayerController seekToTime:kCMTimeZero withCompletionHandler:^(BOOL finished) {
            if (finished) {
                togglePlayPause();
            }
        }];
    }
    else {
        togglePlayPause();
    }
}

#pragma mark Notifications

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
    [self refreshButton];
}

@end
