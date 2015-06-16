//
//  RTSPlaybackActivityIndicatorView.m
//  RTSMediaPlayer Demo
//
//  Created by Cédric Foellmi on 10/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSPlaybackActivityIndicatorView.h"
#import "RTSMediaPlayerController.h"

@implementation RTSPlaybackActivityIndicatorView

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateUponPlaybackStateChange:)
													 name:RTSMediaPlayerPlaybackStateDidChangeNotification
												   object:nil];
	}
	return self;
}

- (void)updateUponPlaybackStateChange:(NSNotification *)notif
{
	RTSMediaPlayerController *controller = notif.object;
	BOOL visible = (controller.playbackState == RTSMediaPlaybackStatePreparing ||
					controller.playbackState == RTSMediaPlaybackStateStalled ||
					controller.playbackState == RTSMediaPlaybackStateSeeking);
	
	self.hidden = !visible;
}

@end
