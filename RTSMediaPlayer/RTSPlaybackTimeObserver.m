//
//  Created by Samuel Défago on 30.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSPlaybackTimeObserver.h"

#import <libextobjc/EXTScope.h>

// FIXME: Too many events received when a livestream switches automatically to live, it seems

static void *s_kvoContext  = &s_kvoContext;

@interface RTSPlaybackTimeObserver ()

@property (nonatomic) CMTime interval;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, copy) void (^block)(CMTime time);

@property (nonatomic, weak) AVPlayer *player;

@property (nonatomic) id playbackStartObserver;
@property (nonatomic) id periodicTimeObserver;

@end

@implementation RTSPlaybackTimeObserver

#pragma mark - Object lifecycle

- (instancetype) initWithInterval:(CMTime)interval queue:(dispatch_queue_t)queue block:(void (^)(CMTime time))block
{
	NSParameterAssert(block);
	
	if (self = [super init])
	{
		self.interval = interval;
		self.queue = queue;
		self.block = block;
	}
	return self;
}

#pragma mark - Associating with a player

- (void) attachToMediaPlayer:(AVPlayer *)player
{
	if (self.player == player)
	{
		return;
	}
	
	if (self.player)
	{
		[self detach];
	}
	
	self.player = player;
	[self.player addObserver:self forKeyPath:@"currentItem.playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:s_kvoContext];
	
	[self resetObservers];
}

- (void) detach
{
	[self removeObservers];
	
	[self.player removeObserver:self forKeyPath:@"currentItem.playbackLikelyToKeepUp" context:s_kvoContext];
	self.player = nil;
}

#pragma mark - Observers

- (void) resetObservers
{
	[self removeObservers];
	
	if (! self.player)
	{
		return;
	}
	
	CMTime startTime = CMTimeAdd(self.player.currentItem.currentTime, CMTimeMake(1., 10.));
	
	// Use a boundary time observer to detect when playback begins. Using a periodic time observer only would namely lead to many block
	// executions when the player starts. Using a boundary time observer makes it possible to filter out these irrelevant events
	@weakify(self)
	self.playbackStartObserver = [self.player addBoundaryTimeObserverForTimes:@[[NSValue valueWithCMTime:startTime]] queue:self.queue usingBlock:^{
		@strongify(self)
		
		// Once playback begin has been detected, the observer can be discarded
		[self.player removeTimeObserver:self.playbackStartObserver];
		self.playbackStartObserver = nil;
		
		// Use a periodic time observer for periodic block execution
		@weakify(self)
		self.periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:self.interval queue:self.queue usingBlock:^(CMTime time) {
			@strongify(self)
			
			// A periodic time observer also triggers block execution when the player playback status changes. If the player is paused,
			// reset all observers so that the process starts again when playback resumes
			if (self.player.rate == 0.)
			{
				[self resetObservers];
				return;
			}
			
			self.block(time);
		}];
	}];
}

- (void) removeObservers
{
	if (self.playbackStartObserver)
	{
		[self.player removeTimeObserver:self.playbackStartObserver];
		self.playbackStartObserver = nil;
	}
	
	if (self.periodicTimeObserver)
	{
		[self.player removeTimeObserver:self.periodicTimeObserver];
		self.periodicTimeObserver = nil;
	}
}

#pragma mark - KVO

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// Called when playback is resumed
	if (context == s_kvoContext && [keyPath isEqualToString:@"currentItem.playbackLikelyToKeepUp"])
	{
		[self resetObservers];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
