//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPictureInPictureButton.h"

#import "NSBundle+SRGMediaPlayer.h"
#import "SRGMediaPlayerController.h"

static UIImage *SRGPictureInPictureButtonStartImage(void);
static UIImage *SRGPictureInPictureButtonStopImage(void);

static void commonInit(SRGPictureInPictureButton *self);

@interface SRGPictureInPictureButton ()

@property (nonatomic, weak) UIButton *button;

@end

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
                                                 selector:@selector(srg_pictureInPictureButton_pictureInPictureStateDidChange:)
                                                     name:SRGMediaPlayerPictureInPictureStateDidChangeNotification
                                                   object:mediaPlayerController];
    }
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self updateAppearanceForMediaPlayerController:self.mediaPlayerController];
    }
}

#pragma mark Appearance

- (void)updateAppearanceForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    AVPictureInPictureController *pictureInPictureController = mediaPlayerController.pictureInPictureController;
    
    if (pictureInPictureController.pictureInPicturePossible) {
        self.hidden = NO;
        
        UIImage *image = pictureInPictureController.pictureInPictureActive ? SRGPictureInPictureButtonStopImage() : SRGPictureInPictureButtonStartImage();
        [self.button setImage:image forState:UIControlStateNormal];
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
        [self.button setImage:SRGPictureInPictureButtonStartImage() forState:UIControlStateNormal];
    }
    else {
        [pictureInPictureController startPictureInPicture];
        [self.button setImage:SRGPictureInPictureButtonStopImage() forState:UIControlStateNormal];
    }
}

#pragma mark Notifications

- (void)srg_pictureInPictureButton_pictureInPictureStateDidChange:(NSNotification *)notification
{
    [self updateAppearanceForMediaPlayerController:self.mediaPlayerController];
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [self.button setImage:SRGPictureInPictureButtonStartImage() forState:UIControlStateNormal];
}

@end

#pragma mark Static functions

static void commonInit(SRGPictureInPictureButton *self)
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = self.bounds;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [button addTarget:self action:@selector(srg_pictureInPictureButton_togglePictureInPicture:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    self.button = button;
    
    self.hidden = YES;
}

#pragma mark Functions

static UIImage *SRGPictureInPictureButtonStartImage(void)
{
    static UIImage *s_image;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        NSString *imagePath = [[NSBundle srg_mediaPlayerBundle] pathForResource:@"picture_in_picture_start_button" ofType:@"png"];
        s_image = [[UIImage imageWithContentsOfFile:imagePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return s_image;
}

static UIImage *SRGPictureInPictureButtonStopImage(void)
{
    static UIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *imagePath = [[NSBundle srg_mediaPlayerBundle] pathForResource:@"picture_in_picture_stop_button" ofType:@"png"];
        image = [[UIImage imageWithContentsOfFile:imagePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}
