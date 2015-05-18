//
//  Created by Frédéric Humbert-Droz on 16/05/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaFailureOverlayView.h"

@implementation RTSMediaFailureOverlayView

- (void) dealloc
{
	self.mediaPlayerController = nil;
}

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.hidden = YES;
	
	_mediaPlayerController = mediaPlayerController;
	
	if (mediaPlayerController)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackDidFailNotification:) name:RTSMediaPlayerPlaybackDidFailNotification object:mediaPlayerController];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackStateDidChange:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController];
	}
}



#pragma mark - Notifications

- (void) mediaPlayerPlaybackDidFailNotification:(NSNotification *)notification
{
	self.hidden = NO;
}

- (void) mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	if(self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePreparing)
	{
		self.hidden = YES;
	}
}

@end
