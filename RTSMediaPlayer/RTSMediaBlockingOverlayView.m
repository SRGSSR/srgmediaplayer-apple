//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "RTSMediaBlockingOverlayView.h"

@implementation RTSMediaBlockingOverlayView

- (void)dealloc
{
	self.mediaPlayerController = nil;
}

- (void)setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	if (self.mediaPlayerController) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:RTSMediaPlayerPlaybackSeekingUponBlockingNotification
													  object:self.mediaPlayerController];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:RTSMediaPlayerPlaybackStateDidChangeNotification
													  object:self.mediaPlayerController];
	}
	
	self.hidden = YES;
	
	_mediaPlayerController = mediaPlayerController;
	
	if (mediaPlayerController) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mediaPlayerPlaybackSeekingUponBlockingNotification:)
													 name:RTSMediaPlayerPlaybackSeekingUponBlockingNotification
												   object:mediaPlayerController];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mediaPlayerPlaybackStateDidChange:)
													 name:RTSMediaPlayerPlaybackStateDidChangeNotification
												   object:mediaPlayerController];
	}
}



#pragma mark - Notifications

- (void)mediaPlayerPlaybackSeekingUponBlockingNotification:(NSNotification *)notification
{
	self.hidden = NO;
	
	NSError *error = notification.userInfo[RTSMediaPlayerPlaybackSeekingUponBlockingReasonInfoKey];
	self.textLabel.text = [error localizedDescription];
}

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	if (self.mediaPlayerController.playbackState == RTSMediaPlaybackStateReady) {
		self.hidden = YES;
	}
}

@end
