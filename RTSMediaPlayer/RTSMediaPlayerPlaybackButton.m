//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerPlaybackButton.h"

#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerIconTemplate.h"

@implementation RTSMediaPlayerPlaybackButton

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	if (_mediaPlayerController) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:RTSMediaPlayerPlaybackStateDidChangeNotification
													  object:_mediaPlayerController];
	}
	
	_mediaPlayerController = mediaPlayerController;
	[self refreshButton];

	if (mediaPlayerController) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mediaPlayerPlaybackStateDidChange:)
													 name:RTSMediaPlayerPlaybackStateDidChangeNotification
												   object:mediaPlayerController];
	}
}

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	[self refreshButton];
}

- (void)play
{
	[self.mediaPlayerController play];
	[self refreshButton];
}

- (void)pause
{
	[self.mediaPlayerController pause];
	[self refreshButton];
}

- (void)refreshButton
{
	BOOL isPlaying = self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	SEL action = isPlaying ? @selector(pause) : @selector(play);

	[self removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
	[self addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];

	UIImage *normalImage = nil;
	UIImage *highlightedImage = nil;
	if (isPlaying) {
		normalImage = [RTSMediaPlayerIconTemplate pauseImageWithSize:self.bounds.size color:self.normalColor];
		highlightedImage = [RTSMediaPlayerIconTemplate pauseImageWithSize:self.bounds.size color:self.hightlightColor];
	}
	else {
		normalImage = [RTSMediaPlayerIconTemplate playImageWithSize:self.bounds.size color:self.normalColor];
		highlightedImage = [RTSMediaPlayerIconTemplate playImageWithSize:self.bounds.size color:self.hightlightColor];
	}
	[self setImage:normalImage forState:UIControlStateNormal];
	[self setImage:highlightedImage forState:UIControlStateHighlighted];
}

- (void)setBounds:(CGRect)bounds
{
	[super setBounds:bounds];
	[self refreshButton];
}

- (void)setNormalColor:(UIColor *)normalColor
{
	_normalColor = normalColor;
	[self refreshButton];
}

- (void)setHightlightColor:(UIColor *)hightlightColor
{
	_hightlightColor = hightlightColor;
	[self refreshButton];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	[self refreshButton];
}

@end
