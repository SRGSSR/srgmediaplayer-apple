//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/RTSMediaPlayerConstants.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 *  RTSMediaPlayback is a protocol shared between the media player controller and the segments controller.
 *  When medias have segment, the segments controller must be used to control the playback.
 */
@protocol RTSMediaPlayback <NSObject>

/**
 *  -------------------------
 *  @name Controling Playback
 *  -------------------------
 */

/**
 *  Returns the current playback state of the media player.
 */
@property (readonly) RTSMediaPlaybackState playbackState;

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
 *  @param completionHandler the completion handler
 */
- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

/**
 *  Play at the specific time
 *
 *  @param time time
 */
- (void)playAtTime:(CMTime)time;

/**
 *  Prepare to play the media specified with its identifier at given time.
 *
 *  @param identifier the identifier of the media to be played.
 *  @param time time
 */
- (void)playIdentifier:(NSString *)identifier atTime:(CMTime)time;

/**
 *  ------------------------------------
 *  @name Accessing playback information
 *  ------------------------------------
 */

/**
 *  The player item
 */
- (AVPlayerItem *)playerItem;

/**
 *  The current media time range (might be empty or indefinite)
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *  The media type
 */
@property (nonatomic, readonly) RTSMediaType mediaType;

/**
 *  The stream type
 */
@property (nonatomic, readonly) RTSMediaStreamType streamType;

/**
 *  YES iff the stream is currently played in live conditions
 */
@property (nonatomic, readonly, getter=isLive) BOOL live;

/**
 *  --------------------
 *  @name Time observers
 *  --------------------
 */

/**
 *  Register a block for periodical execution. Unlike usual AVPlayer time observers, such observers not only run during playback, but
 *  also when paused. This makes such observers very helpful when UI must be updated continously, even when playback is paused, e.g.
 *  in the case of DVR streams
 *
 *  @param interval Time interval between block executions
 *  @param queue    The serial queue onto which block should be enqueued (main queue if NULL)
 *  @param block	The block to be periodically executed
 *
 *  @discussion There is no need to KVO-observe the presence or not of the AVPlayer instance before registration. You can register
 *              time observers earlier if needed
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
