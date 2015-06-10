//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 *  The RTSMediaPlayback is a protocol shared between the media player controller, and the segments controller.
 *  When medias have segment, the segments controller must be used to control the playback.
 */
@protocol RTSMediaPlayback <NSObject>

/**
 *  -------------------------
 *  @name Controling Playback
 *  -------------------------
 */

/**
 *  Prepare to play
 */
- (void)prepareToPlay;

/**
 *  Play
 */
- (void)play;

/**
 *  Start playing media specified with its identifier.
 *
 *  @param identifier the identifier of the media to be played.
 *
 *  @discussion the dataSource will be used to determine the URL of the media.
 */
- (void)playIdentifier:(NSString *)identifier;

/**
 *  Pause
 */
- (void)pause;

/**
 *  Reset
 */
- (void)reset;

/**
 *  Mute the volume of the playback;
 *
 *  @param flag A boolean value
 */
- (void)mute:(BOOL)flag;

/**
 *  Indicates whether the playback is muted or not.
 *
 *  @return Returns YES if the playback is muted.
 */
- (BOOL)isMuted;

/**
 *  Seek to specific time of the playback.
 *
 *  @param time              time in seconds
 *  @param completionHandler the completion handler.
 */
- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

/**
 *  Play at the specific time. When there is no blocked segment, is equivalent to seekToTime: with a play on completion.
 *
 *  @param time time
 */
- (void)playAtTime:(CMTime)time;

// *** Accessing Playback Information ***

- (AVPlayerItem *)playerItem;

/**
 *  --------------------
 *  @name Time Observers
 *  --------------------
 */
/**
 *  Register a block for periodical execution during playback. Playback observers are more reliable than periodic time
 *  observers which trigger block execution also when the player state changes. Such observers are therefore especially
 *  useful when some work needs to be done periodically in a reliable way
 *
 *  @param interval Time interval between block executions
 *  @param queue    The serial queue onto which block should be enqueued (main queue if NULL)
 *  @param block	The block to be executed during playback
 *
 *  @return The time observer. The observer is retained by the media player controller, you can store a weak reference
 *          to it to remove it at a later time if needed
 */
- (id)addPlaybackTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block;

/**
 *  Remove a playback time observer (does nothing if the observer is not registered)
 *
 *  @param playbackTimeObserver The playback time observer to remove
 */
- (void)removePlaybackTimeObserver:(id)observer;

@end
