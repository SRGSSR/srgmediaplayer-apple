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

@interface RTSMediaPlayerController ()

@property (readonly) RTSMediaPlayerView *playerView;

@end

@implementation RTSMediaPlayerController

@synthesize view = _view;

#pragma mark Object lifecycle

- (void)dealloc
{
	self.player = nil;			// Unregister KVO
}

#pragma mark Getters and setters

- (void)setPlayer:(AVPlayer *)player
{
	AVPlayer *previousPlayer = self.playerView.playerLayer.player;
	if (previousPlayer) {
		[player removeObserver:self forKeyPath:@"currentItem.status" context:s_kvoContext];
	}
	
	self.playerView.playerLayer.player = player;
	
	if (player) {
		[player addObserver:self forKeyPath:@"currentItem.status" options:0 context:s_kvoContext];
	}
}

- (AVPlayer *)player
{
	return self.playerView.playerLayer.player;
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

#pragma mark Playback

- (void)playURL:(NSURL *)URL
{
	AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:URL];
	self.player = [AVPlayer playerWithPlayerItem:playerItem];
	[self.player play];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	// TODO: Warning: Might not be executed on the main thread
	
	if (context == s_kvoContext) {
		if ([keyPath isEqualToString:@"currentItem.status"]) {
			
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
