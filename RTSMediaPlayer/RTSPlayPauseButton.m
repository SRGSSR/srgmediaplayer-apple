//
//  Created by Frédéric Humbert-Droz on 05/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSPlayPauseButton.h"
#import <RTSMediaPlayer/RTSMediaPlayerController.h>

@interface RTSPlayPauseButton ()

@property (nonatomic, strong) UIBezierPath *pauseBezierPath;
@property (nonatomic, strong) UIBezierPath *playBezierPath;

@end

@implementation RTSPlayPauseButton

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	
	[defaultCenter removeObserver:self name:RTSMediaPlayerPlaybackStateDidChangeNotification object:_mediaPlayerController];
	
	_mediaPlayerController = mediaPlayerController;
	
	if (mediaPlayerController)
		[defaultCenter addObserver:self selector:@selector(mediaPlayerPlaybackStateDidChange:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[self updateAction];
}

- (UIColor *) hightlightColor
{
	return _hightlightColor ?: self.drawColor;
}

- (void) setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}



#pragma mark - Actions

- (void) updateAction
{
	SEL action = self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying ? @selector(pause:) : @selector(play:);
	
	[self removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
	[self addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void) play:(id)sender
{
	[self.mediaPlayerController.player play];
}

- (void) pause:(id)sender
{
	[self.mediaPlayerController.player pause];
}



#pragma mark - Notifications

- (void) mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	[self updateAction];
	[self setNeedsDisplay];
}



#pragma mark - Draw view

- (UIBezierPath *) pauseBezierPath
{
	if (!_pauseBezierPath)
	{
		CGFloat middle = CGRectGetMidX(self.bounds);
		CGFloat margin = middle * 1/3;
		CGFloat width = middle - margin;
		CGFloat height = CGRectGetHeight(self.bounds);
		
		_pauseBezierPath = [UIBezierPath bezierPath];
		[_pauseBezierPath moveToPoint:CGPointMake(margin / 2, 0)];
		[_pauseBezierPath addLineToPoint:CGPointMake(width, 0)];
		[_pauseBezierPath addLineToPoint:CGPointMake(width, height)];
		[_pauseBezierPath addLineToPoint:CGPointMake(margin / 2, height)];
		[_pauseBezierPath closePath];
		
		[_pauseBezierPath moveToPoint:CGPointMake(middle + margin / 2, 0)];
		[_pauseBezierPath addLineToPoint:CGPointMake(middle + width, 0)];
		[_pauseBezierPath addLineToPoint:CGPointMake(middle + width, height)];
		[_pauseBezierPath addLineToPoint:CGPointMake(middle + margin / 2, height)];
		[_pauseBezierPath closePath];
	}
	return _pauseBezierPath;
}

- (UIBezierPath *) playBezierPath
{
	if (!_playBezierPath)
	{
		CGFloat width = CGRectGetWidth(self.bounds);
		CGFloat height = CGRectGetHeight(self.bounds);
		
		_playBezierPath = [UIBezierPath bezierPath];
		[_playBezierPath moveToPoint:CGPointMake(0, 0)];
		[_playBezierPath addLineToPoint:CGPointMake(width, height / 2)];
		[_playBezierPath addLineToPoint:CGPointMake(0, height)];
		[_playBezierPath closePath];
	}
	return _playBezierPath;
}

- (void) drawRect:(CGRect)rect
{
	UIColor *color = self.isHighlighted ? self.hightlightColor : self.drawColor;
	[color set];
	
	UIBezierPath *bezierPath = self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying ? self.pauseBezierPath : self.playBezierPath;
	[bezierPath fill];
	[bezierPath stroke];
}

@end
