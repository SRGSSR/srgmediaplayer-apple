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
	self.player = nil;			// Unregister KVO and notifications
}

#pragma mark Getters and setters

- (void)setPlayer:(AVPlayer *)player
{
	AVPlayer *previousPlayer = self.playerView.playerLayer.player;
	if (previousPlayer) {
		[previousPlayer removeObserver:self forKeyPath:@"currentItem.status" context:s_kvoContext];
		[previousPlayer removeObserver:self forKeyPath:@"rate" context:s_kvoContext];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:AVPlayerItemPlaybackStalledNotification
													  object:previousPlayer.currentItem];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:AVPlayerItemDidPlayToEndTimeNotification
													  object:previousPlayer.currentItem];
		
	}
	
	self.playerView.playerLayer.player = player;
	
	if (player) {
		[player addObserver:self forKeyPath:@"currentItem.status" options:0 context:s_kvoContext];
		[player addObserver:self forKeyPath:@"rate" options:0 context:s_kvoContext];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rts_playerItemPlaybackStalled:)
													 name:AVPlayerItemPlaybackStalledNotification
												   object:player.currentItem];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rts_playerItemDidPlayToEnd:)
													 name:AVPlayerItemDidPlayToEndTimeNotification
												   object:player.currentItem];
	}
}

- (AVPlayer *)player
{
	return self.playerView.playerLayer.player;
}

- (void)setPlaybackState:(RTSMediaPlaybackState)playbackState
{
	if (_playbackState == playbackState) {
		return;
	}
	
	[self willChangeValueForKey:@"playbackState"];
	_playbackState = playbackState;
	[self didChangeValueForKey:@"playbackState"];
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

#pragma mark Notifications

- (void)rts_playerItemPlaybackStalled:(NSNotification *)notification
{
	self.playbackState = RTSMediaPlaybackStateStalled;
}

- (void)rts_playerItemDidPlayToEnd:(NSNotification *)notification
{
	self.playbackState = RTSMediaPlaybackStateEnded;
}

#pragma mark KVO

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	if ([key isEqualToString:@"playbackState"]) {
		return NO;
	}
	else {
		return [super automaticallyNotifiesObserversForKey:key];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	// TODO: Warning: Might not be executed on the main thread!
	
	if (context == s_kvoContext) {
		// If the rate or the item status changes, calculate the new playback status
		if ([keyPath isEqualToString:@"currentItem.status"] || [keyPath isEqualToString:@"rate"]) {
			if (self.player.currentItem && self.player.currentItem.status == AVPlayerStatusReadyToPlay) {
				self.playbackState = (self.player.rate == 0.f) ? RTSMediaPlaybackStatePaused : RTSMediaPlaybackStatePlaying;
			}
			else {
				self.playbackState = RTSMediaPlaybackStateIdle;
			}
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
