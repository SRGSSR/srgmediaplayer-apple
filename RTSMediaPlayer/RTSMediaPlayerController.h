//
//  Created by Cédric Luthi on 25.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import <RTSMediaPlayer/RTSMediaPlayback.h>
#import <RTSMediaPlayer/RTSMediaPlayerConstants.h>
#import <RTSMediaPlayer/RTSMediaPlayerControllerDataSource.h>


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
@interface RTSMediaPlayerController : NSObject <RTSMediaPlayback>

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
 *  @discussion This can be used for exemple to listen to `addPeriodicTimeObserverForInterval:queue:usingBlock:` or to
 *  implement advanced behaviors
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
 *  @discussion This property contains the view used for presenting the media content. To display the view into your own
 *  view hierarchy, use the `attachPlayerToView:` method.
 *  This view has two gesture recognziers: a single tap gesture recognizer and a double tap gesture recognizer which 
 *  respectively toggle overlays visibility and toggle the video of aspect between `AVLayerVideoGravityResizeAspectFill` 
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
/**
 *  Activity View
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

@end
