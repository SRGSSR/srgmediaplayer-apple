//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

#import "SRGMediaPlayerConstants.h"
#import "SRGMediaPlayerView.h"
#import "SRGSegment.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  `SRGMediaPlayerController` is inspired by the `MPMoviePlayerController` class. It manages the playback of a media 
 *  from a file or a network stream, but provides only core player functionality. As such, it is intended for custom
 *  media player implementation. If you need a player with limited customization abilities but which you can readily 
 *  use, you should have a look at `SRGMediaPlayerViewController` instead.
 *
 *  ## Functionalities
 *
 * `SRGMediaPlayerController` provides standard player features:
 *    - Audio and video playback for all kinds of streams (on-demand, live, DVR)
 *    - Playback status information (mostly through notifications or KVO)
 *    - Media information extraction
 *
 *  In addition, `SRGMediaPlayerController` optionally supports segments. A segment is part of a media, defined by a
 *  start time and a duration. Segments make it possible to add a logical structure on top of a media, e.g. topics
 *  in a news show, chapters in a movie, and so on. If segments are associated with the media being played, 
 *  `SRGMediaPlayerController` will:
 *    - Report transitions between segments when they occur (through notifications)
 *    - Skip segments which must must not be played (blocked segments)
 *
 *  ## Basic usage
 *
 *  `SRGMediaPlayerController` is a raw media player and is usually not used as is (though it could, for example
 *  when you only need to play audio files).
 *
 *  To implement your own custom media player, you need create your own player class (most probably a view controller),
 *  and to delegate playback to an `SRGMediaPlayerController` instance:
 *    - Instantiate `SRGMediaPlayerController` in your player implementation file. If you are using a storyboard or 
 *      a xib to define your player layout, you can also drop a plain object with Interface Builder and assign it the
 *      `SRGMediaPlayerController` class. Be sure to connect an outlet to it if you need to later refer to it from
 *      witin your code
 *    - When creating a video player, you must add the `view` property somewhere within your view hierarchy so that
 *      the content can be properly displayed:
 *        - If you are instantiating the controller in a storyboard or a nib, this is easily achieved by adding a view 
 *          with the `SRGMediaPlayerView` to your layout, and binding it to the `view` property right from Interface 
 *          Builder.
 *        - If you have instantiated `SRGMediaPlayerController` in code, then you must add the `view` property manually
 *          to your view hierarchy by calling `-[UIView addSubview:]` or one of the similar `UIView` methods. Be sure 
 *          to set constraints or autoresizing masks properly so that the view behaves as expected.
 *      If you only need to implement an audio player, you can skip this step.
 *    - Call one of the play methods to start playing your media
 *
 *  You should now have a working implementation able to play audios or videos. There is no way to pause playback or to 
 *  seek within the media, though. The `SRGMediaPlayer` library provides a few standard controls and overlays with which 
 *  you can easily add such functionalities to your custom player.
 *
 *  ## Controls and overlays
 *
 *  The `SRGMediaPlayer` library provides the following set of controls which can be easily connected to a media player
 *  controller instance to report its status or manage playback.
 *
 *  - Buttons:
 *    - `SRGPlaybackButton`: A button to pause or resume playback
 *    - `SRGPictureInPictureButton`: A button to enter or leave picture in picture playback
 *  - Sliders:
 *    - `SRGTimeSlider`: A slide to see the current playback progress, seek, and display the elapsed and remaining times
 *    - `SRGTimelineSlider`: Similar to the time slider, but with the ability to display specific points of interests
 *                           along its track
 *    - `SRGVolumeView`: A slider to adjust the volume
 *  - Miscellaneous:
 *    - `SRGPlaybackActivityIndicatorView`: An activity indicator displayed when the playing is buffering or seeking
 *    - `SRGAirplayView`: An overlay which is visible when external Airplay playback is active, and which displays the
 *                        current route
 *    - `SRGTimelineView`: A linear collection to display the segments associated with a media
 *
 *  Customizing your player layout using these overlays is straightforward:
 *    - Drop instances of the views onto your player layout you need (or instantiate them in code) and tweak their
 *      appearance
 *    - Set their `mediaPlayerController` property to point at the underlying controller. If your controller was
 *      instantiated in a storyboard or a xib file, this can be entirely done in Interface Builder via ctrl-dragging
 *
 *  Usually, you want to hide overlays after some user inactivity delay. While showing or hiding overlays is something
 *  your implementation is responsible of, the `SRGMediaPlayer` library provides the `SRGActivityGestureRecognizer`
 *  class to easily detect any kind of user activity. Just add this gesture recognizer on the view where you want
 *  to track its activity, and associate a corresponding action to show or hide the interface, as you need.
 *
 *  ## Player lifecycle
 *
 *  `SRGMediaPlayerController` is based around `AVPlayer`, which is publicly exposed as a `player` property. You should
 *  avoid controlling playback by acting on this `AVPlayer` instance directly, but you can still use it for any other
 *  purpose:
 *    - Information extraction (e.g. current `AVPlayerItem`, subtitle and audio channels)
 *    - Key-value observation of some other changes you might be interested in (e.g. IceCast / SHOUTcast information)
 *    - Airplay setup
 *    - Muting the player
 *    - etc.
 *
 *  Since the lifecycle of the `AVPlayer` instance is managed by `SRGMediaPlayerController`, specific customization
 *  points have been exposed. Those take the form of optional blocks to which the player is provided as parameter:
 *    - `playerCreationBlock`: This block is called right after player creation
 *    - `playerDestructionBlock`: This block is called right before player destruction
 *    - `playerConfigurationBlock`: This block is called right after player creation, and each time you call the
 *                                  `-reloadPlayerConfiguration` method
 *
 *  ## Player events
 *
 *  The player emits notifications when important changes are detected:
 *    - Playback state changes and errors. Errors are defined in the `SRGMediaPlayerError.h` header file
 *    - Segment changes and blocked segment skipping
 *  For more information about the available notifications, have a look at the `SRGMediaPlayerConstants.h` header file.
 *
 *  Some controller properties (e.g. the `playbackState` property) are key-value observable. If not stated explicitly,
 *  KVO might be possible but is not guaranteed.
 *
 *  ## Playback management
 *
 *  Several methods have been provided to start playback and pause it, or to seek to a specific time. You can also prepare
 *  the player in a paused state before actually starting playback when you want. As a general rule, play, pause and seek
 *  methods are player instructions to perform those operations: Depending on the state of the player, these operations
 *  are not guaranteed to succeed. In general, you should therefore observe player events, as describe above, for example
 *  when updating your user interface. You cannot namely assume the player will be playing right after `-play` has been
 *  called, for example (but you can still update your interface right after `-play` has been called, by checking the
 *  `playbackState` property). 
 *
 *  In some situations some behaviors can be guaranteed (e.g. when the player has successfully been prepared, calling
 *  `-play` will put it in the playing state immediately) but, in general, you should rely on the playback state property
 *  and respond to its changes.
 *
 *  ## Segments
 *
 *  When playing a media, an optional `segments` parameter can be provided. This parameter must be an array of objects
 *  conforming to the `SRGSegment` protocol. When segments have been supplied to the player, corresponding notifications
 *  will be emitted when segment transitions occur (see above). If you want to display segments, you can use the supplied
 *  `SRGTimelineView` or create your own view, as required by your application.
 *
 *  ## Boundary time and periodic time observers
 *
 *  Three kinds of observers can be set on a player to observe its playback:
 *    - Usual boundary time and periodic time observers, which you define on the `AVPlayer` instance directly by accessing
 *      the `player` property directly. You should use the player creation and destruction blocks to install and remove
 *      them reliably.
 *    - `AVPlayer` periodic time observers only trigger when the player actually plays. In some cases, you still want to
 *      perform periodic updates even when playback is paused (e.g. updating the user interface while a DVR stream is paused).
 *      For such use cases, `SRGMediaPlayerController` provides the `-addPeriodicTimeObserverForInterval:queue:usingBlock:`
 *      method, with which such observers can be defined. Since such observers are bound to the controller, you can set
 *      them up right after controller creation, if you like
 *  For more information about `AVPlayer` observers, please refer to the official Apple documentation.
 */
@interface SRGMediaPlayerController : NSObject

/**
 *  @name Settings
 */

/**
 *  The minimum window length which must be available for a stream to be considered to be a DVR stream, in seconds. The
 *  default value is 0. This setting can be used so that streams detected as DVR ones because their window is small can
 *  properly behave as live streams. This is useful to avoid usual related seeking issues, or slider hiccups during 
 *  playback, most notably
 */
@property (nonatomic) NSTimeInterval minimumDVRWindowLength;

/**
 *  Return the tolerance (in seconds) for a DVR stream to be considered being played in live conditions. If the stream
 *  playhead is located within the last `liveTolerance` seconds of the stream, it is considered to be live. The default 
 *  value is 30 seconds and matches the standard iOS player controller behavior
 */
@property (nonatomic) NSTimeInterval liveTolerance;

/**
 *  @name Player
 */

/**
 *  The instance of the player. You should not control playback directly on this instance, otherwise the behavior is undefined.
 *  You can still use if for any other purposes, e.g. getting information about the player, setting observers, etc. If you need
 *  to alter properties of the player, you should use the lifecycle blocks hooks instead (see below)
 */
@property (nonatomic, readonly, nullable) AVPlayer *player;

/**
 *  The layer used by the player. Use it if you need to change the content gravity or to detect when the player is ready
 *  for display
 */
@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

/**
 *  The view where the player displays its content. Either install in your own view hierarchy, or bind a corresponding view
 *  with the `SRGMediaPlayerView` class in Interface Builder
 */
@property (nonatomic, readonly, nullable) IBOutlet SRGMediaPlayerView *view;

/**
 *  @name Player lifecycle
 */

/**
 *  Optional block which gets called right after player creation
 */
@property (nonatomic, copy, nullable) void (^playerCreationBlock)(AVPlayer *player);

/**
 *  Optional block which gets called right after player creation and when the configuration is reloaded by calling
 *  `-reloadPlayerConfiguration`
 */
@property (nonatomic, copy, nullable) void (^playerConfigurationBlock)(AVPlayer *player);

/**
 *  Optional block which gets called right before player destruction
 */
@property (nonatomic, copy, nullable) void (^playerDestructionBlock)(AVPlayer *player);

/**
 *  Ask the player to reload its configuration by calling the associated configuration block, if any. Does nothing if
 *  the player has not been created yet
 */
- (void)reloadPlayerConfiguration;

/**
 *  @name Playback
 */

/**
 *  Prepare to play the media, starting from the specified time, but with the player paused (if playback is not started
 *  in the completion handler). Segments can be optionally provided. If you want playback to start right after preparation, 
 *  call `-play` from the completion handler (in which case the player will immediately reach the playing state).
 *
 *  @param URL               The URL to play
 *  @param startTime         The time to start at. Use kCMTimeZero to start at the default location:
 *                             - For on-demand streams: At the beginning
 *                             - For live and DVR streams: In live conditions, i.e. at the end of the stream
 *                           If the time is invalid it will be set to kCMTimeZero. Setting a start time outside the
 *                           actual media time range will seek to the nearest location (either zero or the end time)
 *  @param segments          A segment list
 *  @param userInfo          A dictionary to associate arbitrary information with the media being played (for later retrieval).
 *                           This information stays associated with the player controller until it is reset
 *  @param completionHandler The completion block to be called after the player has finished preparing the media. This
 *                           block will only be called if the media could be loaded.
 *
 *  @discussion The player state is set to preparing during all the preparation phase (this is also the state on completion
 *              handler entry). The player state is not updated to paused until the completion handler has been executed.
 *              This way, any change to the player state in the completion handler (e.g. because of a `-play` request) will 
 *              only be reflected after the completion handler has been executed, so that the player transitions from preparing
 *              to this state without transitioning through the paused state.
 */
- (void)prepareToPlayURL:(NSURL *)URL atTime:(CMTime)startTime withSegments:(nullable NSArray<id<SRGSegment>> *)segments userInfo:(nullable NSDictionary *)userInfo completionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Ask the player to play
 *
 *  @discussion Calling this method does not guarantee that the player will be playing right afterwards. If the player
 *              has been prepared it will be the case (see above), but otherwise nothing will happen. For user interface
 *              related changes, you should in general check the value of the `playbackState` property and observe when
 *              it changes.
 */
- (void)play;

/**
 *  Ask the player to pause playback
 *
 *  @discussion See `-play`
 */
- (void)pause;

/**
 *  Ask the player to stop playback. Call `-play` to restart playback with the same content URL, segments and user info
 *
 *  @discussion See `-stop`
 */
- (void)stop;

/**
 *  Ask the player to seek to a given location. A paused player remains paused, while a playing player remains
 *  playing. You can use the completion handler to change the player state if needed, e.g. to automatically
 *  resume playback after a seek has been performed on a paused player
 *
 *  @param startTime         The time to start at. Use kCMTimeZero to start at the default location:
 *                             - For on-demand streams: At the beginning
 *                             - For live and DVR streams: In live conditions, i.e. at the end of the stream
 *                           If the time is invalid it will be set to kCMTimeZero. Setting a start time outside the
 *                           actual media time range will seek to the nearest location (either zero or the end time)
 *  @param toleranceBefore   The tolerance allowed before `time`
 *  @param toleranceAfter    The tolerance allowed after `time`
 *  @param completionHandler The completion block is called when the seek ends. If the seek has been interrupted by
 *                           another seek, the completion handler will be called with finished = NO, otherwise with
 *                           finished = YES
 *
 *  @discussion Upon completion handler entry, the playback state will be up-to-date if the seek finished, otherwise
 *              the player will still be in the seeking state. Note that if the media was not ready to play, seeking
 *              won't take place, and the completion handler won't be called.
 *              Refer to `-[AVPlayer seekToTime:toleranceBefore:toleranceAfter:completionHandler:] documentation
 *              for more information about seek tolerances.
 */
- (void)seekToTime:(CMTime)time withToleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Reset the player to its original idle state with no media URL, segments or user info
 *
 *  @discussion Periodic time observers registered with the controller are not unregistered
 */
- (void)reset;

/**
 *  @name Playback information
 */

/**
 *  The current state of the media player controller
 *
 *  @discussion This property is key-value observable
 */
@property (nonatomic, readonly) SRGMediaPlayerPlaybackState playbackState;

/**
 *  The URL of the content currently being loaded into the player
 */
@property (nonatomic, readonly, nullable) NSURL *contentURL;

/**
 *  The segments which have been loaded into the player
 */
@property (nonatomic, readonly, nullable) NSArray<id<SRGSegment>> *segments;

/**
 *  The user info which has been associated with the media being played
 */
@property (nonatomic, readonly, nullable) NSDictionary *userInfo;

/**
 *  The visible segments which have been loaded into the player
 */
@property (nonatomic, readonly, nullable) NSArray<id<SRGSegment>> *visibleSegments;

/**
 *  The current media time range (might be empty or indefinite)
 *
 *  @discussion Use `CMTimeRange` macros for checking time ranges
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *  The media type (audio / video)
 *
 *  Warning: This information is currently unreliable when Airplay playback has been started before the media is played
 *           Related to https://openradar.appspot.com/27079167
 */
@property (nonatomic, readonly) SRGMediaPlayerMediaType mediaType;

/**
 *  The stream type (live / DVR / VOD)
 *
 *  Warning: This information is currently unreliable when Airplay playback has been started before the media is played
 *           Related to https://openradar.appspot.com/27079167
 */
@property (nonatomic, readonly) SRGMediaPlayerStreamType streamType;

/**
 *  Return YES iff the stream is currently played in live conditions (@see `liveTolerance`)
 */
@property (nonatomic, readonly, getter=isLive) BOOL live;

/**
 *  Return the segment currently being played, nil if none
 */
@property (nonatomic, readonly, nullable) id<SRGSegment> currentSegment;

/**
 *  @name Time observers
 */

/**
 *  Register a block for periodical execution. Unlike usual `AVPlayer` time observers, such observers not only run during playback, but
 *  when the player has been created. They therefore also continue to trigger when the player is paused. This makes such observers very 
 *  helpful when UI must be updated continously when the player is up, for example in the case of DVR streams
 *
 *  @param interval Time interval between block executions
 *  @param queue    The serial queue onto which block should be enqueued (main queue if NULL)
 *  @param block	The block to be periodically executed
 *
 *  @return The time observer. The observer is retained by the media player controller, you can store a weak reference
 *          to it and remove it at a later time if needed
 *
 *  @discussion Your can registers observers with the media player controller when you like (you do not have to wait until the player
 *              is ready, observers will be attached to it automatically when appropriate). Not that such observers are not removed
 *              when the player controller is reset
 */
- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(nullable dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block;

/**
 *  Remove a time observer (does nothing if the observer is not registered)
 *
 *  @param observer The time observer to remove
 */
- (void)removePeriodicTimeObserver:(id)observer;

@end

/**
 *  @name Playback (convenience methods)
 */

@interface SRGMediaPlayerController (Convenience)

/**
 *  Prepare to play the media, starting at its default location
 *
 *  For more information, @see `-prepareToPlayURL:atTime:withSegments:userInfo:completionHandler:`
 */
- (void)prepareToPlayURL:(NSURL *)URL withCompletionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Play a media, starting from the specified time. Segments and user info can be optionally provided
 *
 *  For more information, @see `-prepareToPlayURL:atTime:withSegments:userInfo:completionHandler:`
 *
 *  @discussion The player immediately reaches the playing state
 */
- (void)playURL:(NSURL *)URL atTime:(CMTime)time withSegments:(nullable NSArray<id<SRGSegment>> *)segments userInfo:(nullable NSDictionary *)userInfo;

/**
 *  Play a media, starting at its default location
 *
 *  For more information, @see `-playURL:atTime:withSegments:userInfo:`
 */
- (void)playURL:(NSURL *)URL;

/**
 *  Ask the player to change its status from pause to play or conversely, depending on the state it is in
 *
 *  @discussion See `-play`
 */
- (void)togglePlayPause;

/**
 *  Ask the player to seek to a given location efficiently (the seek might be not perfeclty accurate but will be faster)
 *
 * For more information, @see `-seekToTime:withToleranceBefore:toleranceAfter:completionHandler:`
 */
- (void)seekEfficientlyToTime:(CMTime)time withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 * Ask the player to seek to a given location with no tolerance (this might incur some decoding overhead)
 *
 * For more information, @see `-seekToTime:withToleranceBefore:toleranceAfter:completionHandler:`
 */
- (void)seekPreciselyToTime:(CMTime)time withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Seek to the beginning of the specified segment
 *
 *  @param segment The segment to seek to
 *
 * For more information, @see `-seekToTime:withToleranceBefore:toleranceAfter:completionHandler:`
 */
- (void)seekToSegment:(id<SRGSegment>)segment withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

@end

/**
 *  Picture in picture functionality (not available on all devices)
 *
 *  Remark: When the application is sent to the background, the behavior is the same as the vanilla picture in picture
 *          controller: If the managed player layer is the one of a view controller's root view ('full screen'), picture
 *          in picture is automatically enabled when switching to the background (provided the corresponding flag has been
 *          enabled in the system settings). This is the only case where switching to picture in picture can be made
 *          automatically. Picture in picture must otherwise always be user-triggered, otherwise you application might
 *          get rejected by Apple (@see `AVPictureInPictureController` documentation)
 */
@interface SRGMediaPlayerController (PictureInPicture)

/**
 *  Return the picture in picture controller if picture in picture is available for the device, nil otherwise
 */
@property (nonatomic, readonly, nullable) AVPictureInPictureController *pictureInPictureController;

@end

NS_ASSUME_NONNULL_END
