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

@property (nonatomic, getter=isPlaybackStarted) BOOL playbackStarted;

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
	
	CMTime startTime = CMTimeAdd(self.player.currentItem.currentTime, CMTimeMake(1., 10.));
	
	@weakify(self, player)
	self.playbackStartObserver = [player addBoundaryTimeObserverForTimes:@[[NSValue valueWithCMTime:startTime]] queue:NULL usingBlock:^{
		@strongify(self, player)
		
		self.playbackStarted = YES;
		
		[player removeTimeObserver:self.playbackStartObserver];
		self.playbackStartObserver = nil;
	}];
	
	self.periodicTimeObserver = [player addPeriodicTimeObserverForInterval:self.interval queue:NULL usingBlock:^(CMTime time) {
		if (!self.playbackStarted)
		{
			return;
		}
		
		self.playbackBlock ? self.playbackBlock(time) : nil;
	}];
}

- (void) unregister
{
	[self.player removeTimeObserver:self.playbackStartObserver];
	[self.player removeTimeObserver:self.periodicTimeObserver];
	
	self.playbackStartObserver = nil;
	self.periodicTimeObserver = nil;
	
	self.playbackStarted = NO;
	self.player = nil;
}

@end
