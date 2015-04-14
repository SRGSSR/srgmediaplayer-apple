//
//  Created by Frédéric Humbert-Droz on 05/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerPlaybackButton.h"
#import <RTSMediaPlayer/RTSMediaPlayerController.h>

#import "RTSMediaPlayerIconTemplate.h"

@implementation RTSMediaPlayerPlaybackButton

- (void) dealloc
{
	self.mediaPlayerController = nil;
}

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:RTSMediaPlayerPlaybackStateDidChangeNotification object:_mediaPlayerController];
	
	_mediaPlayerController = mediaPlayerController;
	
	if (!mediaPlayerController)
		return;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackStateDidChange:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController];
}

- (void) mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	[self updateButton];
}

- (void) updateButton
{
	BOOL isPlaying = self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	SEL action = isPlaying ? @selector(pause) : @selector(play);

	[self removeTarget:self.mediaPlayerController action:NULL forControlEvents:UIControlEventTouchUpInside];
	[self addTarget:self.mediaPlayerController action:action forControlEvents:UIControlEventTouchUpInside];

	UIImage *normalImage;
	UIImage *highlightedImage;
	if (isPlaying)
	{
		normalImage = [RTSMediaPlayerIconTemplate pauseImageWithSize:self.bounds.size color:self.normalColor];
		highlightedImage = [RTSMediaPlayerIconTemplate pauseImageWithSize:self.bounds.size color:self.hightlightColor];
	}
	else
	{
		normalImage = [RTSMediaPlayerIconTemplate playImageWithSize:self.bounds.size color:self.normalColor];
		highlightedImage = [RTSMediaPlayerIconTemplate playImageWithSize:self.bounds.size color:self.hightlightColor];
	}
	[self setImage:normalImage forState:UIControlStateNormal];
	[self setImage:highlightedImage forState:UIControlStateHighlighted];
}

- (void) setBounds:(CGRect)bounds
{
	[super setBounds:bounds];
	[self updateButton];
}

- (void) setNormalColor:(UIColor *)normalColor
{
	_normalColor = normalColor;
	[self updateButton];
}

- (void) setHightlightColor:(UIColor *)hightlightColor
{
	_hightlightColor = hightlightColor;
	[self updateButton];
}

@end
