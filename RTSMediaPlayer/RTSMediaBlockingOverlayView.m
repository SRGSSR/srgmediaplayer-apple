//
//  RTSMediaBlockingOverlayView.m
//  RTSMediaPlayer
//
//  Created by Cédric Foellmi on 01/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
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
														name:RTSMediaPlayerPlaybackDidPauseUponBlockingNotification
													  object:self.mediaPlayerController];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:RTSMediaPlayerPlaybackStateDidChangeNotification
													  object:self.mediaPlayerController];
	}
	
	self.hidden = YES;
	
	_mediaPlayerController = mediaPlayerController;
	
	if (mediaPlayerController) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mediaPlayerPlaybackDidPauseUponBlockingNotification:)
													 name:RTSMediaPlayerPlaybackDidPauseUponBlockingNotification
												   object:mediaPlayerController];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mediaPlayerPlaybackStateDidChange:)
													 name:RTSMediaPlayerPlaybackStateDidChangeNotification
												   object:mediaPlayerController];
	}
}



#pragma mark - Notifications

- (void)mediaPlayerPlaybackDidPauseUponBlockingNotification:(NSNotification *)notification
{
	self.hidden = NO;
	
	NSError *error = notification.userInfo[RTSMediaPlayerPlaybackDidPauseUponBlockingReasonInfoKey];
	self.textLabel.text = [error localizedDescription];
}

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	if (self.mediaPlayerController.playbackState == RTSMediaPlaybackStateReady) {
		self.hidden = YES;
	}
}

@end
