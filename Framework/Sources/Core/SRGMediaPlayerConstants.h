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

/**
 *  Notification sent when the player state changes. Use the `SRGMediaPlayerPreviousPlaybackStateKey` to retrieve
 *  previous state information from the notification `userInfo` dictionary
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

/**
 *  Notification sent when the current segment changes. Use the keys available below to retrieve information from
 *  the notification `userInfo`dictionary
 */
OBJC_EXTERN NSString * const SRGMediaPlayerSegmentDidStartNotification;                     // Notification when a segment starts
OBJC_EXTERN NSString * const SRGMediaPlayerSegmentDidEndNotification;                       // Notification when a segment ends
OBJC_EXTERN NSString * const SRGMediaPlayerSegmentKey;                                      // The involved segment as an id<RTSMediaSegment> object
OBJC_EXTERN NSString * const SRGMediaPlayerProgrammaticKey;                                 // Key to an `NSNumber` wrapping a boolean, set to YES if the change was induced programmatically

NS_ASSUME_NONNULL_END
