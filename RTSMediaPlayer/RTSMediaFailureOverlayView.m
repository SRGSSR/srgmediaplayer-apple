//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "RTSMediaFailureOverlayView.h"

@implementation RTSMediaFailureOverlayView

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	if (_mediaPlayerController) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:RTSMediaPlayerPlaybackDidFailNotification
													  object:_mediaPlayerController];

		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:RTSMediaPlayerPlaybackStateDidChangeNotification
													  object:_mediaPlayerController];
	}
	
	self.hidden = YES;
	
	_mediaPlayerController = mediaPlayerController;
	
	if (mediaPlayerController) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mediaPlayerPlaybackDidFailNotification:)
													 name:RTSMediaPlayerPlaybackDidFailNotification
												   object:mediaPlayerController];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mediaPlayerPlaybackStateDidChange:)
													 name:RTSMediaPlayerPlaybackStateDidChangeNotification
												   object:mediaPlayerController];
	}
}



#pragma mark - Notifications

- (void) mediaPlayerPlaybackDidFailNotification:(NSNotification *)notification
{
	self.hidden = NO;
	
	NSError *error = notification.userInfo[RTSMediaPlayerPlaybackDidFailErrorUserInfoKey];
	self.textLabel.text = [error localizedDescription];
}

- (void) mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	if (self.mediaPlayerController.playbackState == RTSMediaPlaybackStateReady) {
		self.hidden = YES;
	}
}

@end
