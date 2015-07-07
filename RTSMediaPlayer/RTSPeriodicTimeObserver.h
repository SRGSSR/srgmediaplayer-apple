//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

/**
 *  Call one or several blocks during playback of an associated player
 */
@interface RTSPeriodicTimeObserver : NSObject

/**
 *  Create a periodic time observer. Does nothing until attached to a player (see -attachToMediaPlayer:)
 *
 *  @param interval    The interval at which the block must be executed
 *  @param queue	   The serial queue onto which block should be enqueued (main queue if NULL)
 */
- (instancetype) initWithInterval:(CMTime)interval queue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER OS_NONNULL_ALL;

/**
 *  Register a block for a given identifier. If a block with the same identifier has already been registered, it
 *  is simply replaced
 *
 *  @param block      The block to register (mandatory)
 *  @param identifier The identifier to which the block must be associated (mandatory)
 */
- (void) setBlock:(void (^)(CMTime time))block forIdentifier:(NSString *)identifier;

/**
 *  Unregister the block matching the provided identifier (does nothing if the identifier is not found)
 *
 *  @param identifier The identifier for which a block must be discarded (mandatory)
 */
- (void) removeBlockWithIdentifier:(id)identifier;

/**
 *  The time interval at which the observer executes all associated blocks
 */
@property (nonatomic, readonly) CMTime interval;

/**
 *  The player to which the time observer has been attached, nil if none
 */
@property (nonatomic, readonly, weak) AVPlayer *player;

/**
 *  Attach to a player. If a previous association existed, it will be removed first
 */
- (void) attachToMediaPlayer:(AVPlayer *)player;

/**
 *  Detach the time observer from the associated player, if any
 */
- (void) detach;

@end
