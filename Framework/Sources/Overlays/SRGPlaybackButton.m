//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPlaybackButton.h"

#import "SRGMediaPlayerIconTemplate.h"

static void commonInit(SRGPlaybackButton *self);

@interface SRGPlaybackButton ()

@property (nonatomic) NSMutableDictionary<NSNumber *, NSNumber *> *streamTypeToStoppingMap;

@end

@implementation SRGPlaybackButton

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self refreshButton];
    }
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

- (void)setStopping:(BOOL)stopping forStreamType:(SRGMediaPlayerStreamType)streamType
{
    if (streamType == SRGMediaPlayerStreamTypeUnknown) {
        return;
    }
    
    self.streamTypeToStoppingMap[@(streamType)] = @(stopping);
    [self refreshButton];
}

#pragma mark UI

- (void)refreshButton
{
    BOOL displaysInterruptionButton = (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying
                                       || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateSeeking
                                       || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateStalled);
    
    [self removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(togglePlayPause:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage *normalImage = nil;
    UIImage *highlightedImage = nil;
    if (displaysInterruptionButton) {
        if ([self hasStopButton]) {
            normalImage = self.stopImage ?: [SRGMediaPlayerIconTemplate stopImageWithSize:self.bounds.size color:self.normalColor];
            highlightedImage = self.stopImage ?: [SRGMediaPlayerIconTemplate stopImageWithSize:self.bounds.size color:self.hightlightColor];
        }
        else {
            normalImage = self.pauseImage ?: [SRGMediaPlayerIconTemplate pauseImageWithSize:self.bounds.size color:self.normalColor];
            highlightedImage = self.pauseImage ?: [SRGMediaPlayerIconTemplate pauseImageWithSize:self.bounds.size color:self.hightlightColor];
        }
    }
    else {
        normalImage = self.playImage ?: [SRGMediaPlayerIconTemplate playImageWithSize:self.bounds.size color:self.normalColor];
        highlightedImage = self.playImage ?: [SRGMediaPlayerIconTemplate playImageWithSize:self.bounds.size color:self.hightlightColor];
    }
    [self setImage:normalImage forState:UIControlStateNormal];
    [self setImage:highlightedImage forState:UIControlStateHighlighted];
}


- (BOOL)hasStopButton
{
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeUnknown) {
        return YES;
    }
    else {
        return [self.streamTypeToStoppingMap[@(self.mediaPlayerController.streamType)] boolValue];
    }
}

#pragma mark Actions

- (void)togglePlayPause:(id)sender
{
    SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerController;
    
    void (^togglePlayPause)(void) = ^{
        if ([self hasStopButton]) {
            if (mediaPlayerController.player.rate == 0.f && mediaPlayerController.contentURL) {
                [mediaPlayerController playURL:mediaPlayerController.contentURL];
            }
            else {
                [mediaPlayerController stop];
            }
        }
        else {
            [mediaPlayerController togglePlayPause];
        }
        [self refreshButton];
    };
    
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
        [mediaPlayerController seekEfficientlyToTime:kCMTimeZero withCompletionHandler:^(BOOL finished) {
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

static void commonInit(SRGPlaybackButton *self)
{
    self.streamTypeToStoppingMap = [NSMutableDictionary dictionary];
}
