//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "RTSMediaPlayerConstants.h"

@protocol RTSMediaPlayerControllerDataSource;

/**
 *  `RTSMediaPlayerController` is inspired by the `MPMoviePlayerController` class.
 *
 *  A media player (of type `RTSMediaPlayerController`) manages the playback of a media from a file or a network stream.
 *  For maximum flexibility, you can incorporate a media player’s view into a view hierarchy owned by your app and have 
 *  it managed by an `RTSMediaPlayerController` instance. If you just need a standard player with a view looking just
 *  like the standard iOS media player, you should simply instantiate an `RTSMediaPlayerViewController` which will manage
 *  the view for you.
 *
 *  The media player controller posts several notifications, see RTSMediaPlayerConstants.h
 *
 *  Errors are handled through the `RTSMediaPlayerPlaybackDidFailNotification` notification. There are two possible
 *  source of errors: either the error comes from the dataSource (see `RTSMediaPlayerControllerDataSource`) or from
 *  the network (playback error).
 *
 *  The media player controller manages its overlays visibility. See the `overlayViews` property.
 *
 *  Methods related to playback can be found in the `RTSMediaPlayback` protocol
 */
@interface RTSMediaPlayerController : NSObject

/**
 *  --------------------------------------------
 *  @name Initializing a Media Player Controller
 *  --------------------------------------------
 */

/**
 *  Returns a `RTSMediaPlayerController` object initialized with the media at the specified URL.
 *
 *  @param contentURL The location of the media file. This file must be located either in your app directory or on a remote server.
 *
 *  @return A media player controller
 */
- (instancetype) initWithContentURL:(NSURL *)contentURL OS_NONNULL_ALL;

/**
 *  Returns a `RTSMediaPlayerController` object initialized with a datasource and a media identifier.
 *
 *  @param identifier The identifier of the media to be played
 *  @param dataSource The data source from which the media URL will be retrieved
 *
 *  @return A media player controller
 */
- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource NS_DESIGNATED_INITIALIZER OS_NONNULL2;

/**
 *  -------------------
 *  @name Player Object
 *  -------------------
 */

/**
 *  The player that provides the media content.
 *
 *  @discussion This can be used to implement advanced behaviors
 */
@property (readonly) AVPlayer *player;

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
@property(readonly) UIView *view;

/**
 *  Attach the player view into specified container view with default autoresizing mask. The player view will have the
 *  same frame as its `containerView`
 *
 *  @param `containerView` The parent view in hierarchy what will contains the player layer
 */
- (void) attachPlayerToView:(UIView *)containerView;

/**
 *  --------------------------------
 *  @name Accessing Media Properties
 *  --------------------------------
 */

/**
 *  The data source from which media information is retrieved
 */
@property (weak) IBOutlet id<RTSMediaPlayerControllerDataSource> dataSource;

/**
 *  The identifier of the media currently attached to the player. You can use this identifier to identify the media through
 *  notifications
 *
 *  @see `initWithContentIdentifier:dataSource:`
 */
@property (readonly, copy, readonly) NSString *identifier;

/**
 *  -------------------
 *  @name Overlay Views
 *  -------------------
 */

/**
 *  View on which user activity is detected (to prevent the UI overlays from being automatically hidden, see 'overlayViews' and
 *  'overlayViewsHidingDelay')
 */
@property (weak) IBOutlet UIView *activityView;

/**
 *  A collection of views that will be shown / hidden automatically or manually when user interacts with the view.
 */
@property (copy) IBOutletCollection(UIView) NSArray *overlayViews;

/**
 *  The delay after which the overlay views are hidden. Default to `RTSMediaPlayerOverlayHidingDelay` (5 sec).
 *  Ignored if <= 0.0;
 */
@property (assign) NSTimeInterval overlayViewsHidingDelay;

/**
 *  Return YES iff overlays are currently visible
 */
@property (readonly, getter=areOverlaysVisible) BOOL overlaysVisible;


/**
 *  -------------------------
 *  @name Controling Playback
 *  -------------------------
 */

/**
 *  Returns the current playback state of the media player. See `RTSMediaPlaybackState` for possible values
 */
@property (readonly) RTSMediaPlaybackState playbackState;

/**
 *  Prepare the player to play, but does not start playback
 */
- (void)prepareToPlay;

/**
 *  Play (prepare the player if not ready yet)
 */
- (void)play;

/**
 *  Prepare the player to play the specified identifier, but does not start playback
 */
- (void)prepareToPlayIdentifier:(NSString *)identifier;

/**
 *  Start playing a media specified using its identifier. Retrieving the media URL requires a data source to be bound
 *  to the player controller
 */
- (void)playIdentifier:(NSString *)identifier;

/**
 *  Pause
 */
- (void)pause;

/**
 *  Releases resources associated with the player. Can be called manually if player resources need to be released
 *  early (otherwise those will be discarded when the controller itself is deallocated)
 */
- (void)reset;

/**
 *  Set to YES to mute playback. Default is NO
 */
@property (nonatomic, getter=isMuted) BOOL muted;

/**
 *  Seek to specific time of the playback. The completion handler (if any) will be called when seeking ends
 */
- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

/**
 *  Play the current media, starting at a specific time (the player seeks if it was already playing)
 */
- (void)playAtTime:(CMTime)time;

/**
 *  Play the current media, starting at a specific time, and calling the completion handler when playback resumes
 *  at the specified time (the player seeks if it was already playing)
 */
- (void)playAtTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

/**
 *  Start playing a media specified using its identifier, starting at a specific time. Retrieving the media URL requires
 *  a data source to be bound to the player controller
 *
 *  @discussion If time is kCMTimeZero, playback will beging at the default position (start of a VOD, or live for a DVR).
 *              If you need to start at the beginning of a DVR stream, use a small time (e.g. CMTimeMakeWithSeconds(1., 4.))
 */
- (void)playIdentifier:(NSString *)identifier atTime:(CMTime)time;

/**
 *  ------------------------------------
 *  @name Accessing playback information
 *  ------------------------------------
 */

/**
 *  Low-level player item information. You can access this item properties if you need more information about the
 *  currently played item
 */
@property (nonatomic, readonly) AVPlayerItem *playerItem;

/**
 *  The current media time range (might be empty or indefinite). Use `CMTimeRange` macros for checking time ranges
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *  The media type (audio / video). See `RTSMediaType` for possible values
 */
@property (nonatomic, readonly) RTSMediaType mediaType;

/**
 *  The stream type (live / DVR / VOD). See `RTSMediaStreamType` for possible values
 */
@property (nonatomic, readonly) RTSMediaStreamType streamType;

/**
 *  Return YES iff the stream is currently played in live conditions
 */
@property (nonatomic, readonly, getter=isLive) BOOL live;

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
- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block;

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
@interface RTSMediaPlayerController (PictureInPicture)

/**
 *  Return the picture in picture controller if available, nil otherwise
 */
@property (nonatomic, readonly) AVPictureInPictureController *pictureInPictureController;

@end
