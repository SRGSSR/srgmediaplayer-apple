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
 *  ---------------
 *  @name Constants
 *  ---------------
 */

// Enumeration of the possible playback states.
typedef NS_ENUM(NSInteger, RTSMediaPlaybackState) {
	RTSMediaPlaybackStatePreparingPlay, // before playing when loading datasource or buffering media
	RTSMediaPlaybackStatePlaying,
	RTSMediaPlaybackStatePaused,
	RTSMediaPlaybackStateEnded			// ends either when ends of media is reached or if an error occurs
};

// Enumeration of the possible finished reasons used by `RTSMediaPlayerPlaybackDidFinishNotification`.
typedef NS_ENUM(NSInteger, RTSMediaFinishReason) {
	RTSMediaFinishReasonPlaybackEnded,	// ended because playerreached the end of the stream
	RTSMediaFinishReasonPlaybackError,	// ended due to an error
	RTSMediaFinishReasonUserExited		// ended without error and also without reaching the end of the stream
};

/**
 *  -------------------
 *  @name Notifications
 *  -------------------
 */

// Posted when movie playback ends or a user exits playback.
FOUNDATION_EXTERN NSString * const RTSMediaPlayerPlaybackDidFinishNotification;
FOUNDATION_EXTERN NSString * const RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey; // NSNumber (RTSMediaFinishReason)

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
 *  <#Description#> Returns the current playback state of the media player.
 */
@property (readonly) RTSMediaPlaybackState playbackState;

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

/**
 *  <#Description#> A collection of views that will be shown/hidden automatically or manually when user interacts with the view.
 */
@property (copy) IBOutletCollection(UIView) NSArray *overlayViews;

@end
