//
//  Created by Cédric Luthi on 25.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import <RTSMediaPlayer/RTSMediaPlayerControllerDataSource.h>

/**
 *  ---------------
 *  @name Constants
 *  ---------------
 */

/**
 *  @enum RTSMediaPlaybackState
 *
 *  Enumeration of the possible playback states.
 */
typedef NS_ENUM(NSInteger, RTSMediaPlaybackState) {
	/**
	 *  Default state when controller is initialized. The player also returns to the idle state when an error occurs or 
	 *  when the `stop` method is called.
	 */
	RTSMediaPlaybackStateIdle,
	
	/**
	 *  The player is preparing to play the media. It will load everything needed to play the media. This can typically 
	 *  take some time under bad network conditions.
	 */
	RTSMediaPlaybackStatePreparing,
	
	/**
	 *  The player is ready to play the media. The `player` property becomes available (i.e. is non-nil) upon entering this state.
	 */
	RTSMediaPlaybackStateReady,
	
	/**
	 *  The media is playing, i.e. you can hear sound and/or see a video playing.
	 */
	RTSMediaPlaybackStatePlaying,

	/**
	 *  The media is seeking (i.e. the playback is paused while looking for another time tick). This can be the result of the
	 *  user moving a slider, or the player itself jumping above a blocked segment.
	 */
	RTSMediaPlaybackStateSeeking,

	/**
	 *  The player is paused at the user request.
	 */
	RTSMediaPlaybackStatePaused,
	
	/**
	 *  The player is stalled, i.e. it is waiting for the media to resume playing.
	 */
	RTSMediaPlaybackStateStalled,
	
	/**
	 *  The player has reached the end of the media and has automatically stopped playback.
	 */
	RTSMediaPlaybackStateEnded,
};

/**
 *  -------------------
 *  @name Notifications
 *  -------------------
 */

FOUNDATION_EXTERN NSString * const RTSMediaPlayerPlaybackSeekingUponBlockingNotification;
FOUNDATION_EXTERN NSString * const RTSMediaPlayerPlaybackSeekingUponBlockingReasonInfoKey;

FOUNDATION_EXTERN NSString * const RTSMediaPlayerPlaybackDidFailNotification;
FOUNDATION_EXTERN NSString * const RTSMediaPlayerPlaybackDidFailErrorUserInfoKey; // NSError

/**
 *  Posted when the playback state changes, either programatically or by the user.
 */
FOUNDATION_EXTERN NSString * const RTSMediaPlayerPlaybackStateDidChangeNotification;
FOUNDATION_EXTERN NSString * const RTSMediaPlayerPreviousPlaybackStateUserInfoKey; // NSNumber (RTSMediaPlaybackState)

/**
 *  RTSMediaPlayerController is inspired by the MPMoviePlayerController class.
 *  A media player (of type RTSMediaPlayerController) manages the playback of a media from a file or a network stream. 
 *  You can incorporate a media player’s view into a view hierarchy owned by your app, or use a RTSMediaPlayerViewController
 *  object to manage the presentation for you.
 *
 *  The media player controller posts several notifications, see the notifications section.
 *
 *  Errors are handled through the `RTSMediaPlayerPlaybackDidFinishNotification` notification. There are two possible 
 *  source of errors: either the error comes from the dataSource (see `RTSMediaPlayerControllerDataSource`) or from 
 *  the network (playback error).
 *
 *  The media player controller manages its overlays visibility. See the `overlayViews` property.
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
 *  @param identifier <#identifier description#>
 *  @param dataSource <#dataSource description#>
 *
 *  @return A media player controller
 */
- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource NS_DESIGNATED_INITIALIZER OS_NONNULL_ALL;

/**
 *  -------------------
 *  @name Player Object
 *  -------------------
 */

/**
 *  The player that provides the media content.
 *
 *  @discussion This can be used for exemple to listen to `addPeriodicTimeObserverForInterval:queue:usingBlock:` or to implement advanced behaviors
 */
@property(readonly) AVPlayer *player;

/**
 *  ------------------------
 *  @name Accessing the View
 *  ------------------------
 */

/**
 *  The view containing the media content.
 *
 *  @discussion This property contains the view used for presenting the media content. To display the view into your own view hierarchy, use the `attachPlayerToView:` method.
 *  This view has two gesture recognziers: a single tap gesture recognizer and a double tap gesture recognizer which respectively toggle overlays visibility and toggle the video of aspect between `AVLayerVideoGravityResizeAspectFill` and `AVLayerVideoGravityResizeAspect`.
 *  If you want to handle taps yourself, you can disable these gesture recognizers and add your own gesture recognizer.
 *
 *  @see attachPlayerToView:
 */
@property(readonly) UIView *view;

/**
 *  Attach the player view into specified container view with default autoresizing mask. The player view will have the same frame as its `containerView`
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
 *  <#Description#>
 */
@property (weak) IBOutlet id<RTSMediaPlayerControllerDataSource> dataSource;

/**
 *  Use this identifier to identify the media through notifications
 *
 *  @see initWithContentIdentifier:dataSource:
 */
@property (copy) NSString *identifier;

/**
 *  Returns the current playback state of the media player.
 */
@property (readonly) RTSMediaPlaybackState playbackState;

/**
 *  --------------------------
 *  @name Controlling Playback
 *  --------------------------
 */

- (void) prepareToPlay;

- (void) play;

- (void) pause;

/**
 *  Start playing media specified with its identifier.
 *
 *  @param identifier the identifier of the media to be played.
 *
 *  @discussion the dataSource will be used to determine the URL of the media.
 */
- (void) playIdentifier:(NSString *)identifier;

/**
 *  Stop playing the current media.
 */
- (void) reset;

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
- (id) addPlaybackTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block;

/**
 *  Remove a playback time observer (does nothing if the observer is not registered)
 *
 *  @param playbackTimeObserver The playback time observer to remove
 */
- (void) removePlaybackTimeObserver:(id)observer;

/**
 *  -------------------
 *  @name Overlay Views
 *  -------------------
 */

FOUNDATION_EXTERN NSString * const RTSMediaPlayerWillShowControlOverlaysNotification;
FOUNDATION_EXTERN NSString * const RTSMediaPlayerDidShowControlOverlaysNotification;
FOUNDATION_EXTERN NSString * const RTSMediaPlayerWillHideControlOverlaysNotification;
FOUNDATION_EXTERN NSString * const RTSMediaPlayerDidHideControlOverlaysNotification;

/**
 *  <#Description#>
 */
@property (weak) IBOutlet UIView *activityView;

/**
 *  A collection of views that will be shown/hidden automatically or manually when user interacts with the view.
 */
@property (copy) IBOutletCollection(UIView) NSArray *overlayViews;

@end
