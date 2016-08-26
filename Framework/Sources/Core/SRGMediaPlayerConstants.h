//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Amount of seconds at the end of a DVR stream, assumed to correspond to live conditions
OBJC_EXTERN NSTimeInterval const SRGLiveDefaultTolerance;

/**
 *  Media types
 */
typedef NS_ENUM(NSInteger, SRGMediaType) {
    /**
     *  Unknown type
     */
    SRGMediaTypeUnknown,
    /**
     *  Video
     */
    SRGMediaTypeVideo,
    /**
     *  Audio
     */
    SRGMediaTypeAudio,
};

/**
 *  Stream types
 */
typedef NS_ENUM(NSInteger, SRGMediaStreamType) {
    /**
     *  Unknown type
     */
    SRGMediaStreamTypeUnknown,
    /**
     *  On-demand stream
     */
    SRGMediaStreamTypeOnDemand,
    /**
     *  Live stream
     */
    SRGMediaStreamTypeLive,
    /**
     *  DVR stream
     */
    SRGMediaStreamTypeDVR,
};

/**
 *  Playback states
 */
typedef NS_ENUM(NSInteger, SRGPlaybackState) {
    /**
     *  The player is idle. This state occurs after the player has been initialized, reset, or when an error has been
     *  encountered
     */
    SRGPlaybackStateIdle,
    /**
     *  A media is being played
     */
    SRGPlaybackStatePlaying,
    /**
     *  The player is seeking to another position
     */
    SRGPlaybackStateSeeking,
    /**
     *  The player is paused
     */
    SRGPlaybackStatePaused,
    /**
     *  The player is stalled, i.e. waiting for media playback to restart (most probably because of poor networking
     *  conditions)
     */
    SRGPlaybackStateStalled,
    /**
     *  The player has reached the end of the media and has automatically stopped playback
     */
    SRGPlaybackStateEnded,
};

// TODO: START

/**
 *  Segment change reasons
 */
typedef NS_ENUM(NSInteger, SRGMediaPlaybackSegmentChange) {
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
 *  Notification sent when the player state changes. Use the `SRGMediaPlayerPreviousPlaybackStateKey` to retrieve
 *  previous state information from the notification `userInfo` dictionary)
 */
OBJC_EXTERN NSString * const SRGMediaPlayerPlaybackStateDidChangeNotification;              // Notification name
OBJC_EXTERN NSString * const SRGMediaPlayerPreviousPlaybackStateKey;                        // Key to access the previous playback state as an `NSNumber` (wrapping an `SRGPlaybackState` value)

/**
 *  Notification sent when playback failed. Use the `SRGMediaPlayerErrorKey` to retrieve an `NSError` 
 *  information from the notification `userInfo` dictionary)
 */
OBJC_EXTERN NSString * const SRGMediaPlayerPlaybackDidFailNotification;                     // Notification name
OBJC_EXTERN NSString * const SRGMediaPlayerErrorKey;                                        // Key to access error information

/**
 *  Notification sent when the picture in picture state changes
 */
OBJC_EXTERN NSString * const SRGMediaPlayerPictureInPictureStateDidChangeNotification;

// TODO: START

/**
 *  Posted when a segment event occurs.
 */
OBJC_EXTERN NSString * const SRGMediaPlaybackSegmentDidChangeNotification;

/**
 *  The key to access the current segment instance as an `id<RTSMediaSegment>`, if any.
 */
OBJC_EXTERN NSString * const SRGMediaPlaybackSegmentChangeSegmentInfoKey;

/**
 *  The key to access the previously played segment instance as an `id<RTSMediaSegment>`, if any.
 */
OBJC_EXTERN NSString * const SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey;

/**
 *  The key to access the segment change value as an `NSNumber` (wrapping an `SRGMediaPlaybackSegmentChange` value).
 */
OBJC_EXTERN NSString * const SRGMediaPlaybackSegmentChangeValueInfoKey;

/**
 *  The key to access an `NSNumber` (wrapping a boolean) indicating whether the change is requested by the user or not.
 */
OBJC_EXTERN NSString * const SRGMediaPlaybackSegmentChangeUserSelectInfoKey;

// TODO: END

NS_ASSUME_NONNULL_END
