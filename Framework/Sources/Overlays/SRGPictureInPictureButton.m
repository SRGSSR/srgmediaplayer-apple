//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPictureInPictureButton.h"

#import "NSBundle+SRGMediaPlayer.h"
#import "SRGMediaPlayerController.h"

UIImage *SRGPictureInPictureButtonStartImage(void);
UIImage *SRGPictureInPictureButtonStopImage(void);

static void commonInit(SRGPictureInPictureButton *self);

@implementation SRGPictureInPictureButton

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

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerPictureInPictureStateDidChangeNotification
                                                      object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self updateAppearanceForMediaPlayerController:mediaPlayerController];
    
    if (mediaPlayerController) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pictureInPictureStateDidChange:)
                                                     name:SRGMediaPlayerPictureInPictureStateDidChangeNotification
                                                   object:mediaPlayerController];
    }
}

#pragma mark Appearance

- (void)updateAppearanceForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    AVPictureInPictureController *pictureInPictureController = mediaPlayerController.pictureInPictureController;
    
    if (! pictureInPictureController.pictureInPicturePossible) {
        self.hidden = YES;
        return;
    }
    
    self.hidden = NO;
    
    UIImage *image = pictureInPictureController.pictureInPictureActive ? SRGPictureInPictureButtonStopImage() : SRGPictureInPictureButtonStartImage();
    [self setImage:image forState:UIControlStateNormal];
}

#pragma mark Actions

- (void)togglePictureInPicture:(id)sender
{
    AVPictureInPictureController *pictureInPictureController = self.mediaPlayerController.pictureInPictureController;

    if (! pictureInPictureController.pictureInPicturePossible) {
        return;
    }

    if (pictureInPictureController.pictureInPictureActive) {
        [pictureInPictureController stopPictureInPicture];
        [self setImage:SRGPictureInPictureButtonStartImage() forState:UIControlStateNormal];
    }
    else {
        [pictureInPictureController startPictureInPicture];
        [self setImage:SRGPictureInPictureButtonStopImage() forState:UIControlStateNormal];
    }
}

#pragma mark Notifications

- (void)pictureInPictureStateDidChange:(NSNotification *)notification
{
    [self updateAppearanceForMediaPlayerController:self.mediaPlayerController];
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [self setTitle:nil forState:UIControlStateNormal];
    [self setImage:SRGPictureInPictureButtonStartImage() forState:UIControlStateNormal];
}

@end

#pragma mark Static functions

static void commonInit(SRGPictureInPictureButton *self)
{
    [self addTarget:self action:@selector(togglePictureInPicture:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark Functions

UIImage *SRGPictureInPictureButtonStartImage(void)
{
    static UIImage *s_image;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        NSString *imagePath = [[NSBundle srg_mediaPlayerBundle] pathForResource:@"picture_in_picture_start_button" ofType:@"png"];
        s_image = [UIImage imageWithContentsOfFile:imagePath];
    });
    return s_image;
}

UIImage *SRGPictureInPictureButtonStopImage(void)
{
    static UIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *imagePath = [[NSBundle srg_mediaPlayerBundle] pathForResource:@"picture_in_picture_stop_button" ofType:@"png"];
        image = [UIImage imageWithContentsOfFile:imagePath];
    });
    return image;
}
