//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>

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


FOUNDATION_EXTERN NSTimeInterval const RTSMediaPlaybackTickInterval; // in seconds.

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

FOUNDATION_EXTERN NSString * const RTSMediaPlayerWillShowControlOverlaysNotification;
FOUNDATION_EXTERN NSString * const RTSMediaPlayerDidShowControlOverlaysNotification;
FOUNDATION_EXTERN NSString * const RTSMediaPlayerWillHideControlOverlaysNotification;
FOUNDATION_EXTERN NSString * const RTSMediaPlayerDidHideControlOverlaysNotification;
