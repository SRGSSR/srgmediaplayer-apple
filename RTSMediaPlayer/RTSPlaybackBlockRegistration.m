//
//  Created by Samuel Défago on 30.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSPlaybackBlockRegistration.h"

@interface RTSPlaybackBlockRegistration ()

@property (nonatomic, copy) void (^playbackBlock)(CMTime time);
@property (nonatomic) CMTime interval;

@property (nonatomic, weak) AVPlayer *player;
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
	self.periodicTimeObserver = [player addPeriodicTimeObserverForInterval:self.interval queue:dispatch_get_main_queue() usingBlock:self.playbackBlock];
}

- (void) unregister
{
	[self.player removeTimeObserver:self.periodicTimeObserver];
	self.player = nil;
}

@end
