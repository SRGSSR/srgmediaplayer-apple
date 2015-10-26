//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSPlaybackActivityIndicatorView.h"
#import "RTSMediaPlayerController.h"

static void commonInit(RTSPlaybackActivityIndicatorView *self);

@implementation RTSPlaybackActivityIndicatorView

- (instancetype)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		commonInit(self);
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder]) {
		commonInit(self);
	}
	return self;
}

- (void)setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	_mediaPlayerController = mediaPlayerController;
	
	[self updateWithMediaPlayerController:mediaPlayerController];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateUponPlaybackStateChange:(NSNotification *)notif
{
	RTSMediaPlayerController *controller = notif.object;
	if (self.mediaPlayerController != controller) {
		return;
	}
	
	[self updateWithMediaPlayerController:controller];
}

- (void)updateWithMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	BOOL visible = (mediaPlayerController.playbackState == RTSMediaPlaybackStatePreparing ||
					mediaPlayerController.playbackState == RTSMediaPlaybackStateStalled ||
					mediaPlayerController.playbackState == RTSMediaPlaybackStateSeeking);
	
	self.hidden = !visible;
}

@end

static void commonInit(RTSPlaybackActivityIndicatorView *self)
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateUponPlaybackStateChange:)
												 name:RTSMediaPlayerPlaybackStateDidChangeNotification
											   object:nil];
}
