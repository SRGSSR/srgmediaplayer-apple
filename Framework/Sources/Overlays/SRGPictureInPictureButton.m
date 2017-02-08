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
@property (nonatomic, weak) UIButton *fakeInterfaceBuilderButton;

@end

@implementation SRGPictureInPictureButton

@synthesize startImage = _startImage;
@synthesize stopImage = _stopImage;
@synthesize alwaysHidden = _alwaysHidden;

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
    self.mediaPlayerController = nil;       // Unregister KVO and notifications
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

- (UIImage *)startImage
{
    return _startImage ?: SRGPictureInPictureButtonStartImage();
}

- (void)setStartImage:(UIImage *)startImage
{
    _startImage = startImage;
    [self updateAppearance];
}

- (UIImage *)stopImage
{
    return _stopImage ?: SRGPictureInPictureButtonStopImage();
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
        return super.intrinsicContentSize;
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
    else if (pictureInPictureController.pictureInPicturePossible) {
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
        [self.button setImage:self.startImage forState:UIControlStateNormal];
    }
    else {
        [pictureInPictureController startPictureInPicture];
        [self.button setImage:self.stopImage forState:UIControlStateNormal];
    }
}

#pragma mark Notifications

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
    fakeInterfaceBuilderButton.frame = self.bounds;
    fakeInterfaceBuilderButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [fakeInterfaceBuilderButton setImage:self.startImage forState:UIControlStateNormal];
    [self addSubview:fakeInterfaceBuilderButton];
    self.fakeInterfaceBuilderButton = fakeInterfaceBuilderButton;
    
    // Hide the normal button
    self.button.hidden = YES;
}

@end

#pragma mark Functions

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
