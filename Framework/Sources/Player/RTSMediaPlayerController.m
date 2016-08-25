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
@property (nonatomic) RTSMediaPlaybackState playbackState;

@end

@implementation RTSMediaPlayerController {
@private
	BOOL _seeking;
}

@synthesize view = _view;

#pragma mark Object lifecycle

- (instancetype)init
{
	if (self = [super init]) {
		self.playbackState = RTSMediaPlaybackStateIdle;
	}
	return self;
}

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
		[player removeObserver:self forKeyPath:@"rate" context:s_kvoContext];
	}
	
	self.playerView.playerLayer.player = player;
	
	if (player) {
		[player addObserver:self forKeyPath:@"currentItem.status" options:0 context:s_kvoContext];
		[player addObserver:self forKeyPath:@"rate" options:0 context:s_kvoContext];
	}
}

- (AVPlayer *)player
{
	return self.playerView.playerLayer.player;
}

- (UIView *)view
{
	if (!_view) {
		_view = [[RTSMediaPlayerView alloc] init];
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

- (void)togglePlayPause
{
	if (self.player.rate == 0.f) {
		[self.player play];
	}
	else {
		[self.player pause];
	}
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	// TODO: Warning: Might not be executed on the main thread!
	
	if (context == s_kvoContext) {
		if ([keyPath isEqualToString:@"currentItem.status"]) {
			if (self.player.status == AVPlayerStatusReadyToPlay) {
				self.playbackState = RTSMediaPlaybackStateReady;
			}
			else {
				self.playbackState = RTSMediaPlaybackStateIdle;
			}
		}
		else if ([keyPath isEqualToString:@"rate"]) {
			if (self.player.rate == 0.f) {
				self.playbackState = RTSMediaPlaybackStatePaused;
			}
			else {
				self.playbackState = RTSMediaPlaybackStatePlaying;
			}
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
