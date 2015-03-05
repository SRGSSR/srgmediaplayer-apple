//
//  RTSPlayPauseButton.m
//  RTSMediaPlayer
//
//  Created by Frédéric Humbert-Droz on 05/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSPlayPauseButton.h"
#import <RTSMediaPlayer/RTSMediaPlayerController.h>

@interface RTSPlayPauseButton ()

@property (nonatomic, strong) UIBezierPath *pauseBezierPath;
@property (nonatomic, strong) UIBezierPath *playBezierPath;

@property (nonatomic, assign) RTSMediaPlaybackState playbackState;

@end

@implementation RTSPlayPauseButton

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackStateDidChangeNotification:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:nil];
}

- (UIColor *) hightlightColor
{
	return _hightlightColor ?: _drawColor;
}

- (void) setPlaybackState:(RTSMediaPlaybackState)playbackState
{
	_playbackState = playbackState;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self setNeedsDisplay];
	});
}

- (void) setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}



#pragma mark - Notifications

- (void) mediaPlayerPlaybackStateDidChangeNotification:(NSNotification *)notification
{
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	self.playbackState = mediaPlayerController.playbackState;
}



#pragma mark - Draw view

- (void) drawRect:(CGRect)rect
{
	UIColor *color = self.isHighlighted ? self.hightlightColor : self.drawColor;
	if (color)
		[color set];

	if (self.playbackState == RTSMediaPlaybackStatePlaying)
		[self drawPauseBezierPath];
	else
		[self drawPlayBezierPath];
}

- (void) drawPauseBezierPath
{
	if (!_pauseBezierPath) {
		_pauseBezierPath = [UIBezierPath bezierPath];
		
		CGFloat middle = CGRectGetWidth(self.frame)/2;
		CGFloat margin = middle * 1/3;
		CGFloat width = middle - margin;
		CGFloat height = CGRectGetHeight(self.frame);
		
		// Subpath for 1.
		[_pauseBezierPath moveToPoint:CGPointMake(margin/2, 0)];
		[_pauseBezierPath addLineToPoint:CGPointMake(width, 0)];
		[_pauseBezierPath addLineToPoint:CGPointMake(width, height)];
		[_pauseBezierPath addLineToPoint:CGPointMake(margin/2, height)];
		[_pauseBezierPath closePath];
		
		// Subpath for 2.
		[_pauseBezierPath moveToPoint:CGPointMake(middle+margin/2, 0)];
		[_pauseBezierPath addLineToPoint:CGPointMake(middle+width, 0)];
		[_pauseBezierPath addLineToPoint:CGPointMake(middle+width, height)];
		[_pauseBezierPath addLineToPoint:CGPointMake(middle+margin/2, height)];
		[_pauseBezierPath closePath];
	}
	
	[_pauseBezierPath fill];
	[_pauseBezierPath stroke];
}

- (void) drawPlayBezierPath
{
	if (!_playBezierPath) {
		_playBezierPath = [UIBezierPath bezierPath];
		
		CGFloat width = CGRectGetWidth(self.frame);
		CGFloat height = CGRectGetHeight(self.frame);
		
		[_playBezierPath moveToPoint:CGPointMake(0, 0)];
		[_playBezierPath addLineToPoint:CGPointMake(width, height/2)];
		[_playBezierPath addLineToPoint:CGPointMake(0.0, height)];
		[_playBezierPath closePath];
	}
	
	[_playBezierPath fill];
	[_playBezierPath stroke];
}

@end
