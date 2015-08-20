//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import <SRGMediaPlayer/RTSMediaPlayback.h>
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
 *  Errors are handled through the `RTSMediaPlayerPlaybackDidFinishNotification` notification. There are two possible 
 *  source of errors: either the error comes from the dataSource (see `RTSMediaPlayerControllerDataSource`) or from 
 *  the network (playback error).
 *
 *  The media player controller manages its overlays visibility. See the `overlayViews` property.
 *
 *  Methods related to playback can be found in the RTSMediaPlayback protocol
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
@property (readonly, copy) NSString *identifier;

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

@end
