//
//  Created by Samuel Défago on 30.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

/**
 *  Call a block during playback of an associated player. A playback time observer is similar to a periodic time 
 *  observer, but its periodic execution is reliable. A periodic time observer namely executes the associated block 
 *  not only during playback at regular time intervals, but also when the player status changes. This leads to more 
 *  calls than expected when a task must be performed in a reliable regular fashion. Playback time observers are
 *  especially useful when regularly retrieving metadata from a webservice during playback, for example.
 *
 *  Since a playback time observer calls the associated block only when the associated player is actually playing,
 *  stream information (e.g. duration, current time) is available and reliable when implementing the block. A 
 *  playback time observer can therefore also be used to update information only available during playback
 *  (e.g. stream position, remaining time).
 */
@interface RTSPlaybackTimeObserver : NSObject

/**
 *  Create a playback time observer. Does nothing until attached to a player (see -attachToMediaPlayer:)
 *
 *  @param interval    The interval at which the block must be executed
 *  @param queue	   The serial queue onto which block should be enqueued (main queue if NULL)
 *  @param block	   The block to be executed during playback (mandatory)
 */
- (instancetype) initWithInterval:(CMTime)interval queue:(dispatch_queue_t)queue block:(void (^)(CMTime time))block NS_DESIGNATED_INITIALIZER OS_NONNULL_ALL;

/**
 *  Playback time observer parameters
 */
@property (nonatomic, readonly, copy) void (^block)(CMTime time);
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
