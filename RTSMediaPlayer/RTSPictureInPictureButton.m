//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSPictureInPictureButton.h"

#import "NSBundle+RTSMediaPlayer.h"
#import "RTSMediaPlayerController.h"

extern NSString * const RTSMediaPlayerPictureInPictureStateChangeNotification;

static void commonInit(RTSPictureInPictureButton *self);

@implementation RTSPictureInPictureButton

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

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	if (_mediaPlayerController) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:RTSMediaPlayerPictureInPictureStateChangeNotification
													  object:_mediaPlayerController];
	}
	
	_mediaPlayerController = mediaPlayerController;
	[self updateAppearanceForMediaPlayerController:mediaPlayerController];
	
	if (mediaPlayerController) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(pictureInPictureStateDidChange:)
													 name:RTSMediaPlayerPictureInPictureStateChangeNotification
												   object:mediaPlayerController];
	}
}

#pragma mark Appearance

- (void)updateAppearanceForMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	AVPictureInPictureController *pictureInPictureController = mediaPlayerController.pictureInPictureController;
	
	if (!pictureInPictureController.pictureInPicturePossible) {
		self.hidden = YES;
		return;
	}
	
	self.hidden = NO;
	
	UIImage *image = pictureInPictureController.pictureInPictureActive ? RTSPictureInPictureButtonStopImage() : RTSPictureInPictureButtonStartImage();
	[self setImage:image forState:UIControlStateNormal];
}

#pragma mark Actions

- (void)togglePictureInPicture:(id)sender
{
	AVPictureInPictureController *pictureInPictureController = self.mediaPlayerController.pictureInPictureController;
	
	if (!pictureInPictureController.pictureInPicturePossible) {
		return;
	}
	
	if (pictureInPictureController.pictureInPictureActive) {
		[pictureInPictureController stopPictureInPicture];
		[self setImage:RTSPictureInPictureButtonStartImage() forState:UIControlStateNormal];
	}
	else {
		[pictureInPictureController startPictureInPicture];
		[self setImage:RTSPictureInPictureButtonStopImage() forState:UIControlStateNormal];
	}
}

#pragma mark Notifications

- (void)pictureInPictureStateDidChange:(NSNotification *)notification
{
	[self updateAppearanceForMediaPlayerController:self.mediaPlayerController];
}

@end

#pragma mark Static functions

static void commonInit(RTSPictureInPictureButton *self)
{
	[self addTarget:self action:@selector(togglePictureInPicture:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark Functions

UIImage *RTSPictureInPictureButtonStartImage(void)
{
	static UIImage *image;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *imagePath = [[NSBundle RTSMediaPlayerBundle] pathForResource:@"picture_in_picture_start_button" ofType:@"png"];
		image = [UIImage imageWithContentsOfFile:imagePath];
	});
	return image;
}

UIImage *RTSPictureInPictureButtonStopImage(void)
{
	static UIImage *image;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *imagePath = [[NSBundle RTSMediaPlayerBundle] pathForResource:@"picture_in_picture_stop_button" ofType:@"png"];
		image = [UIImage imageWithContentsOfFile:imagePath];
	});
	return image;
}
