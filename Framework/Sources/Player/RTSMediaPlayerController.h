//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

#import "RTSMediaPlayerConstants.h"

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
@property (nonatomic, readonly) UIView *view;

/**
 *  Attach the player view into specified container view with default autoresizing mask. The player view will have the
 *  same frame as its `containerView`
 *
 *  @param `containerView` The parent view in hierarchy what will contains the player layer
 */
- (void)attachPlayerToView:(UIView *)containerView;

/**
 *  -------------------
 *  @name Overlay Views
 *  -------------------
 */

@property (nonatomic, readonly) AVPlayerItem *playerItem;

/**
 *  -------------------------
 *  @name Controling Playback
 *  -------------------------
 */

/**
 *  Start playing a media specified using its identifier. Retrieving the media URL requires a data source to be bound
 *  to the player controller
 */
- (void)playURL:(NSURL *)URL;

@end
