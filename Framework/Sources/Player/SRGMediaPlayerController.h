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
 *    - Media playback (audios and videos)
 *    - Playback status information (mostly through notifications or KVO)
 *    - Media information (stream and media type)
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
 *
 *  For maximum flexibility, you can incorporate a media player’s view into a view hierarchy owned by your app and have
 *  it managed by an `SRGMediaPlayerController` instance. If you just need a standard player with a view looking just
 *  like the standard iOS media player, you should simply instantiate an `SRGMediaPlayerViewController` which will manage
 *  the view for you.
 *
 *  The media player controller posts several notifications, see SRGMediaPlayerConstants.h
 *
 *  Errors are handled through the `SRGMediaPlayerPlaybackDidFailNotification` notification. There are two possible
 *  source of errors: either the error comes from the dataSource (see `RTSMediaPlayerControllerDataSource`) or from
 *  the network (playback error).
 *
 *  The media player controller manages its overlays visibility. See the `overlayViews` property.
 *
 *  Methods related to playback can be found in the `RTSMediaPlayback` protocol
 */
@interface SRGMediaPlayerController : NSObject

/**
 *  -------------------
 *  @name Player Object
 *  -------------------
 */

/**
 *  The player that provides the media content.
 *
 *  @discussion This can be used to implement advanced behaviors. This property should not be used to alter player properties,
 *              but merely for KVO registration or information extraction. Altering player properties in any way results in
 *              undefined behavior
 */
@property (nonatomic, readonly) AVPlayer *player;

@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

/**
 *  ------------------------
 *  @name Accessing the View
 *  ------------------------
 */

/**
 *  The view containing the media content.
 *
 *  @discussion This property contains the view used for presenting the media content. To display the view into your own
 *  view hierarchy, use the `attachPlayerToView:` method.
 *
 *  This view has two gesture recognziers: a single tap gesture recognizer and a double tap gesture recognizer which
 *  toggle overlays visibility, respectively the video aspect between `AVLayerVideoGravityResizeAspectFill` and
 *  `AVLayerVideoGravityResizeAspect`.
 *
 *  If you want to handle taps yourself, you can disable these gesture recognizers and add your own gesture recognizers.
 *
 *  @see `attachPlayerToView:`
 */
@property (nonatomic, readonly) IBOutlet SRGMediaPlayerView *view;

@property (nonatomic, copy) void (^playerCreationBlock)(AVPlayer *player);
@property (nonatomic, copy) void (^playerConfigurationBlock)(AVPlayer *player);
@property (nonatomic, copy) void (^playerDestructionBlock)(AVPlayer *player);

- (void)reloadPlayerConfiguration;

@property (nonatomic, readonly) SRGPlaybackState playbackState;

@property (nonatomic, readonly, nullable) NSURL *contentURL;
@property (nonatomic, readonly) NSArray<id<SRGSegment>> *segments;

/**
 *  -------------------------
 *  @name Controling Playback
 *  -------------------------
 */

/**
 *  Start playing a media specified using its identifier. Retrieving the media URL requires a data source to be bound
 *  to the player controller
 */
- (void)prepareToPlayURL:(NSURL *)URL atTime:(CMTime)startTime withSegments:(nullable NSArray<id<SRGSegment>> *)segments completionHandler:(nullable void (^)(BOOL finished))completionHandler;
- (void)prepareToPlayURL:(NSURL *)URL atTime:(CMTime)startTime withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

- (void)playURL:(NSURL *)URL atTime:(CMTime)time withSegments:(nullable NSArray<id<SRGSegment>> *)segments;
- (void)playURL:(NSURL *)URL atTime:(CMTime)time;

- (void)playURL:(NSURL *)URL withSegments:(nullable NSArray<id<SRGSegment>> *)segments;
- (void)playURL:(NSURL *)URL;

- (void)togglePlayPause;

- (void)seekToTime:(CMTime)time withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;
- (void)seekToSegment:(id<SRGSegment>)segment withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;;

- (void)reset;

/**
 *  The current media time range (might be empty or indefinite). Use `CMTimeRange` macros for checking time ranges
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *  The media type (audio / video). See `SRGMediaType` for possible values
 *
 *  Warning: Is currently unreliable when Airplay playback has been started before the media is played
 *           Related to https://openradar.appspot.com/27079167
 */
@property (nonatomic, readonly) SRGMediaType mediaType;

/**
 *  The stream type (live / DVR / VOD). See `SRGMediaStreamType` for possible values
 *
 *  Warning: Is currently unreliable when Airplay playback has been started before the media is played
 *           Related to https://openradar.appspot.com/27079167
 */
@property (nonatomic, readonly) SRGMediaStreamType streamType;

/**
 *  Return YES iff the stream is currently played in live conditions
 */
@property (nonatomic, readonly, getter=isLive) BOOL live;

/**
 *  Return the segment currently being played, nil if none
 */
@property (nonatomic, readonly, nullable) id<SRGSegment> currentSegment;

/**
 *  The minimum window length which must be available for a stream to be considered to be a DVR stream, in seconds. The
 *  default value is 0. This setting can be used so that streams detected as DVR ones because their window is small can
 *  behave as live streams. This is useful to avoid usual related seeking issues, or slider hiccups during playback, most
 *  notably
 */
@property (nonatomic) NSTimeInterval minimumDVRWindowLength;

/**
 *  Return the tolerance (in seconds) for a DVR stream to be considered being played in live conditions. If the stream
 *  playhead is located within the last liveTolerance conditions of the stream, it is considered to be live, not live
 *  otherwise. The default value is 30 seconds and matches the standard iOS behavior
 */
@property (nonatomic) NSTimeInterval liveTolerance;

/**
 *  --------------------
 *  @name Time observers
 *  --------------------
 */

/**
 *  Register a block for periodical execution. Unlike usual `AVPlayer` time observers, such observers not only run during playback, but
 *  also when paused. This makes such observers very helpful when UI must be updated continously, even when playback is paused, e.g.
 *  in the case of DVR streams
 *
 *  @param interval Time interval between block executions
 *  @param queue    The serial queue onto which block should be enqueued (main queue if NULL)
 *  @param block	The block to be periodically executed
 *
 *  @discussion There is no need to KVO-observe the presence or not of the `AVPlayer` instance before registration. You can register
 *              time observers earlier if needed
 *
 *  @return The time observer. The observer is retained by the media player controller, you can store a weak reference
 *          to it and remove it at a later time if needed
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
 *  Picture in picture functionality (not available on all devices)
 *
 *  Remark: When the application is sent to the background, the behavior is the same as the vanilla picture in picture
 *          controller: If the managed player layer is the one of a view controller's root view ('full screen'), picture
 *          in picture is automatically enabled when switching to the background (provided the corresponding flag has been
 *          enabled in the system settings). This is the only case where switching to picture in picture can be made
 *          automatically. Picture in picture must otherwise always be user-triggered, otherwise you application might
 *          get rejected by Apple (see `AVPictureInPictureController` documentation)
 */
@interface SRGMediaPlayerController (PictureInPicture)

/**
 *  Return the picture in picture controller if available, nil otherwise
 */
@property (nonatomic, readonly, nullable) AVPictureInPictureController *pictureInPictureController;

@end

NS_ASSUME_NONNULL_END
