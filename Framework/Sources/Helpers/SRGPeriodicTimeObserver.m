//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPeriodicTimeObserver.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@interface SRGPeriodicTimeObserver ()

@property (nonatomic) CMTime interval;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic) NSMutableDictionary *blocks;
@property (nonatomic) id timeObserver;

@end

@implementation SRGPeriodicTimeObserver

#pragma mark Object lifecycle

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    return [self initWithInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL];
}

#pragma clang diagnostic pop

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
    [self removeObservers];
}

#pragma mark Associating with a player

- (void)attachToMediaPlayer:(AVPlayer *)player
{
    if (self.player == player) {
        return;
    }
    
    [self removeObservers];
    self.player = player;
    [self startObservers];
}

- (void)detachFromMediaPlayer
{
    [self removeObservers];
    self.player = nil;
}

#pragma mark Managing blocks

- (void)setBlock:(void (^)(CMTime time))block forIdentifier:(NSString *)identifier
{
    if (self.blocks.count == 0) {
        [self startObservers];
    }
    
    [self.blocks setObject:[block copy] forKey:identifier];
}

- (BOOL)hasBlockWithIdentifier:(id)identifier
{
    return self.blocks[identifier] != nil;
}

- (void)removeBlockWithIdentifier:(id)identifier
{
    [self.blocks removeObjectForKey:identifier];
    
    if (self.blocks.count == 0) {
        [self removeObservers];
    }
}

- (NSUInteger)registrationCount
{
    return self.blocks.count;
}

#pragma mark Observers

- (void)startObservers
{
    if (! self.player || self.timeObserver) {
        return;
    }
    
    void (^notify)(CMTime) = ^(CMTime time) {
        if (self.player.currentItem.status != AVPlayerItemStatusReadyToPlay) {
            return;
            
        }
        
        for (void (^block)(CMTime) in [self.blocks allValues]) {
            dispatch_async(self.queue, ^{
                block(time);
            });
        }
    };
    
    @weakify(self)
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:self.interval queue:self.queue usingBlock:^(CMTime time) {
        @strongify(self)
        if (! self.player) {    // It may have disappeared, as it is a weak property
            [self removeObservers];
            return;
        }
        
        notify(time);
    }];
    
    [self.player addObserver:self keyPath:@keypath(self.player.currentItem.seekableTimeRanges) options:0 block:^(MAKVONotification * _Nonnull notification) {
        notify(self.player.currentTime);
    }];
}

- (void)removeObservers
{
    [self.player removeTimeObserver:self.timeObserver];
    self.timeObserver = nil;
    
    [self.player removeObserver:self keyPath:@keypath(self.player.currentItem.seekableTimeRanges)];
}

@end
