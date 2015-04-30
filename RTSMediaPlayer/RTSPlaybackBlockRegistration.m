//
//  Created by Samuel Défago on 30.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSPlaybackBlockRegistration.h"

#import <libextobjc/EXTScope.h>

@interface RTSPlaybackBlockRegistration ()

@property (nonatomic, copy) void (^playbackBlock)(CMTime time);
@property (nonatomic) CMTime interval;

@property (nonatomic, weak) AVPlayer *player;

@property (nonatomic) id playbackStartObserver;
@property (nonatomic) id periodicTimeObserver;

@end

@implementation RTSPlaybackBlockRegistration

- (instancetype) initWithPlaybackBlock:(void (^)(CMTime time))playbackBlock interval:(CMTime)interval
{
	if (self = [super init])
	{
		self.playbackBlock = playbackBlock;
		self.interval = interval;
	}
	return self;
}

- (void) registerWithMediaPlayer:(AVPlayer *)player
{
	if (self.player)
	{
		[self unregister];
	}
	
	self.player = player;
	
	[self resetObservers];
}

- (void) resetObservers
{
	[self removeObservers];
	
	CMTime startTime = CMTimeAdd(self.player.currentItem.currentTime, CMTimeMake(1., 10.));
	
	@weakify(self)
	self.playbackStartObserver = [self.player addBoundaryTimeObserverForTimes:@[[NSValue valueWithCMTime:startTime]] queue:NULL usingBlock:^{
		@strongify(self)
		
		[self.player removeTimeObserver:self.playbackStartObserver];
		self.playbackStartObserver = nil;
		
		@weakify(self)
		self.periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:self.interval queue:NULL usingBlock:^(CMTime time) {
			@strongify(self)
			
			if (self.player.rate == 0.)
			{
				[self resetObservers];
				return;
			}
			
			self.playbackBlock ? self.playbackBlock(time) : nil;
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

- (void) unregister
{
	[self removeObservers];
	
	self.player = nil;
}

@end
