//
//  Created by Samuel Défago on 30.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

/**
 *  Call one or several blocks during playback of an associated player. A playback time observer is similar to a 
 *  periodic time observer, but its periodic execution is reliable. 
 *
 *  A periodic time observer namely executes the associated block (only a single one) not only during playback at
 *  regular time intervals, but also when the player status changes. This leads to more calls than expected when 
 *  a task must be performed in a reliable regular fashion.
 *
 *  Since a playback time observer calls the associated blocks only when the associated player is actually playing,
 *  stream information (e.g. duration, current time) is available and reliable within a block implementation. A
 *  playback time observer can therefore also be used to update information only available during playback
 *  (e.g. stream position, remaining time).
 */
@interface RTSPlaybackTimeObserver : NSObject

/**
 *  Create a playback time observer. Does nothing until attached to a player (see -attachToMediaPlayer:)
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
