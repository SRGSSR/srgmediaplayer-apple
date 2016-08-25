//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <objc/runtime.h>

#import <libextobjc/EXTScope.h>

#import "RTSMediaPlayerController.h"

#import "RTSMediaPlayerError.h"
#import "RTSMediaPlayerView.h"
#import "RTSPeriodicTimeObserver.h"
#import "RTSActivityGestureRecognizer.h"
#import "RTSMediaPlayerLogger.h"

#import "NSBundle+RTSMediaPlayer.h"

static void *s_kvoContext = &s_kvoContext;

NSTimeInterval const RTSMediaPlayerOverlayHidingDelay = 5.0;
NSTimeInterval const RTSMediaLiveDefaultTolerance = 30.0;		// same tolerance as built-in iOS player

NSString * const RTSMediaPlayerErrorDomain = @"ch.srgssr.SRGMediaPlayer";

@interface RTSMediaPlayerController () <UIGestureRecognizerDelegate>

@property (readwrite) AVPlayer *player;
@property (readonly) RTSMediaPlayerView *playerView;

@end

@implementation RTSMediaPlayerController

@synthesize view = _view;

#pragma mark Playback

- (void)playURL:(NSURL *)URL
{}

#pragma mark - View

- (void)attachPlayerToView:(UIView *)containerView
{
	[self.view removeFromSuperview];
	self.view.frame = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds));
	[containerView insertSubview:self.view atIndex:0];
}

- (UIView *)view
{
	if (!_view) {
		RTSMediaPlayerView *mediaPlayerView = [RTSMediaPlayerView new];
		mediaPlayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_view = mediaPlayerView;
	}
	
	return _view;
}

- (RTSMediaPlayerView *)playerView
{
	return (RTSMediaPlayerView *)self.view;
}

@end
