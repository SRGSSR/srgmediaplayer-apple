//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSPeriodicTimeObserver.h"

#import <libextobjc/EXTScope.h>

static void *s_kvoContext  = &s_kvoContext;

@interface RTSPeriodicTimeObserver ()
@property (nonatomic) CMTime interval;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic) NSMutableDictionary *blocks;
@property (nonatomic) NSTimer *timer;
@end

@implementation RTSPeriodicTimeObserver

- (instancetype)init
{
	return [self initWithInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC) queue:NULL];
}

- (instancetype)initWithInterval:(CMTime)interval queue:(dispatch_queue_t)queue
{
	if (self = [super init]) {
		self.interval = interval;
		self.queue = queue ?: dispatch_get_main_queue();
		self.blocks = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)dealloc
{
	[self removeObserver];
}

#pragma mark - Associating with a player

- (void)attachToMediaPlayer:(AVPlayer *)player
{
	if (self.player == player) {
		return;
	}
	
	[self removeObserver];
	self.player = player;
	[self startObserver];
}

- (void)detachFromMediaPlayer
{
	[self removeObserver];
	self.player = nil;
}

#pragma mark - Managing blocks

- (void)setBlock:(void (^)(CMTime time))block forIdentifier:(NSString *)identifier
{
	NSParameterAssert(block);
	NSParameterAssert(identifier);
	
	if (self.blocks.count == 0) {
		[self startObserver];
	}
	
	[self.blocks setObject:[block copy] forKey:identifier];
}

- (void)removeBlockWithIdentifier:(id)identifier
{
	NSParameterAssert(identifier);
	
	[self.blocks removeObjectForKey:identifier];
	
	if (self.blocks.count == 0) {
		[self removeObserver];
	}
}

#pragma mark - Observers

- (void)startObserver
{
	if (!self.player || self.timer) {
		return;
	}
	
	self.timer = [NSTimer scheduledTimerWithTimeInterval:CMTimeGetSeconds(self.interval)
												  target:self
												selector:@selector(timerTick:)
												userInfo:nil
												 repeats:YES];
}

- (void)timerTick:(NSTimer *)timer
{
	if (!self.player) { // It may have disappeared, as it is a weak property
		[self removeObserver];
		return;
	}
	
	for (void (^block)(CMTime) in [self.blocks allValues]) {
		dispatch_async(self.queue, ^{
			block(self.player.currentTime);
		});
	}
}

- (void)removeObserver
{
	[self.timer invalidate];
	self.timer = nil;
}

@end
