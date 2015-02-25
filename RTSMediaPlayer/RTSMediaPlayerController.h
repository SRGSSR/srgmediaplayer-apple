//
//  Created by Cédric Luthi on 25.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <RTSMediaPlayer/RTSMediaPlayerControllerDataSource.h>

/**
 *  RTSMediaPlayerController is inspired by the MPMoviePlayerController class.
 *  A media player (of type RTSMediaPlayerController) manages the playback of a media from a file or a network stream. You can incorporate a media player’s view into a view hierarchy owned by your app, or use a RTSMediaPlayerViewController object to manage the presentation for you.
 *
 *  The media player controller posts several notifications, see the notifications section.
 *
 *  Errors are handled through the `RTSMediaPlayerPlaybackDidFinishNotification` notification. There are two possible source of errors: either the error comes from the dataSource (see `RTSMediaPlayerControllerDataSource`) or from the network (playback error).
 *
 *  The media player controller manages its overlays visibility. See the `overlayViews` property.
 */

/**
 *  -------------------
 *  @name Notifications
 *  -------------------
 */

FOUNDATION_EXTERN NSString * const RTSMediaPlayerPlaybackDidFinishNotification;

@interface RTSMediaPlayerController : NSObject

/**
 *  --------------------------------------------
 *  @name Initializing a Media Player Controller
 *  --------------------------------------------
 */

/**
*  <#Description#>
*
*  @param contentURL <#contentURL description#>
*
*  @return A media player controller
*/
- (instancetype) initWithContentURL:(NSURL *)contentURL OS_NONNULL_ALL;

/**
 *  <#Description#>
 *
 *  @param identifier <#identifier description#>
 *  @param dataSource <#dataSource description#>
 *
 *  @return <#return value description#>
 */
- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource NS_DESIGNATED_INITIALIZER OS_NONNULL_ALL;

/**
 *  --------------------------------
 *  @name Accessing Media Properties
 *  --------------------------------
 */

/**
 *  <#Description#>
 */
@property (readonly) id<RTSMediaPlayerControllerDataSource> dataSource;

/**
 *  <#Description#> Use this identifier to identify the media through notifications
 */
@property (readonly) NSString *identifier;

/**
 *  --------------------------
 *  @name Controlling Playback
 *  --------------------------
 */

- (void) play;
- (void) playIdentifier:(NSString *)identifier;
- (void) pause;
- (void) seekToTime:(NSTimeInterval)time;

/**
 *  ----------------------------
 *  @name Managing Overlay Views
 *  ----------------------------
 */

@property (copy) IBOutletCollection(UIView) NSArray *overlayViews;

@end
