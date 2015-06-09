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


/**
 *  @enum RTSMediaPlaybackSegmentChange
 *
 *  Enumeration of the possible changes occuring during playback related to segments.
 */
typedef NS_ENUM(NSInteger, RTSMediaPlaybackSegmentChange) {
	/**
	 *  An identified segment (visible or not) is being started, while not being inside a segment before.
	 */
	RTSMediaPlaybackSegmentStart,
	/**
	 *  An identified segment (visible or not) is being ended, without another one to start.
	 */
	RTSMediaPlaybackSegmentEnd,
	/**
	 *  An identified segment (visible or not) is being started, while being inside another segment before.
	 */
	RTSMediaPlaybackSegmentSwitch,
	/**
	 *  The playback is being seek to a later value, because it reached a blocked segment.
	 */
	RTSMediaPlaybackSegmentSeekUponBlockingStart,
	/**
	 *  The seek has finished.
	 */
	RTSMediaPlaybackSegmentSeekUponBlockingEnd,
};

FOUNDATION_EXTERN NSTimeInterval const RTSMediaPlaybackTickInterval; // in seconds.

typedef NS_ENUM(NSInteger, RTSMediaPlaybackSeekingReason) {
	RTSMediaPlaybackSeekingReasonSegmentBlocked,
	RTSMediaPlaybackSeekingReasonSegmentSelected
};

/**
 *  -------------------
 *  @name Notifications
 *  -------------------
 */

/**
 *  Posted when a segment event occurs.
 */
FOUNDATION_EXTERN NSString * const RTSMediaPlaybackSegmentDidChangeNotification;

/**
 *  The key to access the new segment instance, when entering a new segment (start, and switch events).
 */
FOUNDATION_EXTERN NSString * const RTSMediaPlaybackSegmentChangeSegmentInfoKey;

/**
 *  The key to access the segment change value.
 */
FOUNDATION_EXTERN NSString * const RTSMediaPlaybackSegmentChangeValueInfoKey;

FOUNDATION_EXTERN NSString * const RTSMediaPlayerPlaybackSeekingReasonInfoKey;

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
