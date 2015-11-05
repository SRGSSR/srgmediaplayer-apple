//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import <SRGMediaPlayer/RTSMediaPlayerConstants.h>
#import <SRGMediaPlayer/RTSMediaPlayerControllerDataSource.h>

/**
 *  RTSMediaPlayerController is inspired by the MPMoviePlayerController class.
 *  A media player (of type RTSMediaPlayerController) manages the playback of a media from a file or a network stream.
 *  You can incorporate a media player’s view into a view hierarchy owned by your app, or use a RTSMediaPlayerViewController
 *  object to manage the presentation for you.
 *
 *  The media player controller posts several notifications, see RTSMediaPlayerConstants.h
 *
 *  Errors are handled through the `RTSMediaPlayerPlaybackDidFailNotification` notification. There are two possible
 *  source of errors: either the error comes from the dataSource (see `RTSMediaPlayerControllerDataSource`) or from
 *  the network (playback error).
 *
 *  The media player controller manages its overlays visibility. See the `overlayViews` property.
 *
 *  Methods related to playback can be found in the RTSMediaPlayback protocol
 */
@interface RTSMediaPlayerController : NSObject

/**
 *  --------------------------------------------
 *  @name Initializing a Media Player Controller
 *  --------------------------------------------
 */

/**
 *  Returns a RTSMediaPlayerController object initialized with the media at the specified URL.
 *
 *  @param contentURL The location of the media file. This file must be located either in your app directory or on a remote server.
 *
 *  @return A media player controller
 */
- (instancetype) initWithContentURL:(NSURL *)contentURL OS_NONNULL_ALL;

/**
 *  Returns a RTSMediaPlayerController object initialized with a datasource and a media identifier.
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
 *  This view has two gesture recognziers: a single tap gesture recognizer and a double tap gesture recognizer which
 *  respectively toggle overlays visibility and toggle the video aspect between `AVLayerVideoGravityResizeAspectFill`
 *  and `AVLayerVideoGravityResizeAspect`.
 *  If you want to handle taps yourself, you can disable these gesture recognizers and add your own gesture recognizer.
 *
 *  @see attachPlayerToView:
 */
@property(readonly) UIView *view;

/**
 *  Attach the player view into specified container view with default autoresizing mask. The player view will have the
 *  same frame as its `containerView`
 *
 *  @param containerView The parent view in hierarchy what will contains the player layer
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
 *  @see initWithContentIdentifier:dataSource:
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
 *  A collection of views that will be shown/hidden automatically or manually when user interacts with the view.
 */
@property (copy) IBOutletCollection(UIView) NSArray *overlayViews;

/**
 *  The delay after which the overlay views are hidden. Default to RTSMediaPlayerOverlayHidingDelay (5 sec).
 *  Ignored if <= 0.0;
 */
@property (assign) NSTimeInterval overlayViewsHidingDelay;


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

/**
 *  Picture in picture functionality (not available on all devices)
 *
 *  Remark: When the application is sent to the background, the behavior is the same as the vanilla picture in picture
 *          controller: If the managed player layer is the one of a view controller's root view ('full screen'), picture
 *          in picture is automatically enabled when switching to the background (provided the corresponding flag has been
 *          enabled in the system settings). This is the only case where switching to picture in picture can be made
 *          automatically. Picture in picture must otherwise always be user-triggered, otherwise you application might
 *          get rejected by Apple (see AVPictureInPictureController documentation)
 */
@interface RTSMediaPlayerController (PictureInPicture)

/**
 *  Return the picture in picture controller if available, nil otherwise
 */
@property (nonatomic, readonly) AVPictureInPictureController *pictureInPictureController;

@end
