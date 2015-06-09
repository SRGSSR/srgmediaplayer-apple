//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "RTSPlaybackTimeObserver.h"

#import <libextobjc/EXTScope.h>

// FIXME: A block is executed several times when seeking to another position in the stream. Fix

static void *s_kvoContext  = &s_kvoContext;

@interface RTSPlaybackTimeObserver ()

@property (nonatomic) CMTime interval;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, weak) AVPlayer *player;

@property (nonatomic) NSMutableDictionary *blocks;

@property (nonatomic) id playbackStartObserver;
@property (nonatomic) id periodicTimeObserver;

@end

@implementation RTSPlaybackTimeObserver

#pragma mark - Object lifecycle

- (instancetype) initWithInterval:(CMTime)interval queue:(dispatch_queue_t)queue
{
	if (self = [super init])
	{
		self.interval = interval;
		self.queue = queue;
		self.blocks = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void) dealloc
{
    [self removeObservers];
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

#pragma mark - Managing blocks

- (void) setBlock:(void (^)(CMTime time))block forIdentifier:(NSString *)identifier
{
    NSParameterAssert(block);
    NSParameterAssert(identifier);
    
    if (self.blocks.count == 0)
    {
        [self resetObservers];
    }
    
    [self.blocks setObject:[block copy] forKey:identifier];
}

- (void) removeBlockWithIdentifier:(id)identifier
{
    NSParameterAssert(identifier);
    
    [self.blocks removeObjectForKey:identifier];
    
    if (self.blocks.count == 0)
    {
        [self removeObservers];
    }
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
            
            for (void (^block)(CMTime) in [self.blocks allValues]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					block(time);					
				});
            }
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
        [self removeObservers];
		[self resetObservers];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
