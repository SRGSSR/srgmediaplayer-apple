//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Amount of seconds at the end of a DVR stream, assumed to correspond to live conditions
OBJC_EXTERN NSTimeInterval const RTSLiveDefaultTolerance;

/**
 *  Media types
 */
typedef NS_ENUM(NSInteger, RTSMediaType) {
    /**
     *  Unknown type
     */
    RTSMediaTypeUnknown,
    /**
     *  Video
     */
    RTSMediaTypeVideo,
    /**
     *  Audio
     */
    RTSMediaTypeAudio,
};

/**
 *  Stream types
 */
typedef NS_ENUM(NSInteger, RTSMediaStreamType) {
    /**
     *  Unknown type
     */
    RTSMediaStreamTypeUnknown,
    /**
     *  On-demand stream
     */
    RTSMediaStreamTypeOnDemand,
    /**
     *  Live stream
     */
    RTSMediaStreamTypeLive,
    /**
     *  DVR stream
     */
    RTSMediaStreamTypeDVR,
};

/**
 *  Playback states
 */
typedef NS_ENUM(NSInteger, RTSPlaybackState) {
    /**
     *  The player is idle. This state occurs after the player has been initialized, reset, or when an error has been
     *  encountered
     */
    RTSPlaybackStateIdle,
    /**
     *  A media is being played
     */
    RTSPlaybackStatePlaying,
    /**
     *  The player is seeking to another position
     */
    RTSPlaybackStateSeeking,
    /**
     *  The player is paused
     */
    RTSPlaybackStatePaused,
    /**
     *  The player is stalled, i.e. waiting for media playback to restart (most probably because of poor networking
     *  conditions)
     */
    RTSPlaybackStateStalled,
    /**
     *  The player has reached the end of the media and has automatically stopped playback
     */
    RTSPlaybackStateEnded,
};

// TODO: START

/**
 *  Segment change reasons
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

// TODO: END

/**
 *  Notification sent when the player state changes. Use the `RTSMediaPlayerPreviousPlaybackStateUserInfoKey` to retrieve
 *  previous state information from the notification `userInfo` dictionary)
 */
OBJC_EXTERN NSString * const RTSMediaPlayerPlaybackStateDidChangeNotification;           // Notification name
OBJC_EXTERN NSString * const RTSMediaPlayerPreviousPlaybackStateUserInfoKey;             // Key to access the previous playback state as an `NSNumber` (wrapping an `RTSPlaybackState` value)

/**
 *  Notification sent when playback failed. Use the `RTSMediaPlayerPlaybackDidFailErrorUserInfoKey` to retrieve an `NSError` 
 *  information from the notification `userInfo` dictionary)
 */
OBJC_EXTERN NSString * const RTSMediaPlayerPlaybackDidFailNotification;                  // Notification name
OBJC_EXTERN NSString * const RTSMediaPlayerPlaybackDidFailErrorUserInfoKey;              // Key to access error information

/**
 *  Notification sent when the picture in picture state changes
 */
OBJC_EXTERN NSString * const RTSMediaPlayerPictureInPictureStateChangeNotification;

// TODO: START

/**
 *  Posted when a segment event occurs.
 */
OBJC_EXTERN NSString * const RTSMediaPlaybackSegmentDidChangeNotification;

/**
 *  The key to access the current segment instance as an `id<RTSMediaSegment>`, if any.
 */
OBJC_EXTERN NSString * const RTSMediaPlaybackSegmentChangeSegmentInfoKey;

/**
 *  The key to access the previously played segment instance as an `id<RTSMediaSegment>`, if any.
 */
OBJC_EXTERN NSString * const RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey;

/**
 *  The key to access the segment change value as an `NSNumber` (wrapping an `RTSMediaPlaybackSegmentChange` value).
 */
OBJC_EXTERN NSString * const RTSMediaPlaybackSegmentChangeValueInfoKey;

/**
 *  The key to access an `NSNumber` (wrapping a boolean) indicating whether the change is requested by the user or not.
 */
OBJC_EXTERN NSString * const RTSMediaPlaybackSegmentChangeUserSelectInfoKey;

// TODO: END

NS_ASSUME_NONNULL_END
