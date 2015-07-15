//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <SRGMediaPlayer/RTSMediaPlayerConstants.h>
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
 *  The current media time range (might be empty or indefinite)
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *  The stream type
 */
@property (readonly) RTSMediaStreamType streamType;

/**
 *  --------------------
 *  @name Time Observers
 *  --------------------
 */
/**
 *  Register a block for periodical execution during playback
 *
 *  @param interval Time interval between block executions
 *  @param queue    The serial queue onto which block should be enqueued (main queue if NULL)
 *  @param block	The block to be executed during playback
 *
 *  @return The time observer. The observer is retained by the media player controller, you can store a weak reference
 *          to it to remove it at a later time if needed
 */
- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block;

/**
 *  Remove a time observer (does nothing if the observer is not registered)
 *
 *  @param observer The time observer to remove
 */
- (void)removePeriodicTimeObserver:(id)observer;

@end
