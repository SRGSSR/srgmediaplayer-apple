//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Amount of seconds at the end of a DVR stream, assumed to correspond to live conditions
OBJC_EXTERN NSTimeInterval const SRGMediaPlayerLiveDefaultTolerance;

/**
 *  Media types
 */
typedef NS_ENUM(NSInteger, SRGMediaPlayerMediaType) {
    /**
     *  Unknown type
     */
    SRGMediaPlayerMediaTypeUnknown = 0,
    /**
     *  Video
     */
    SRGMediaPlayerMediaTypeVideo,
    /**
     *  Audio
     */
    SRGMediaPlayerMediaTypeAudio,
};

/**
 *  Stream types
 */
typedef NS_ENUM(NSInteger, SRGMediaPlayerStreamType) {
    /**
     *  Unknown type
     */
    SRGMediaPlayerStreamTypeUnknown = 0,
    /**
     *  On-demand stream
     */
    SRGMediaPlayerStreamTypeOnDemand,
    /**
     *  Live stream
     */
    SRGMediaPlayerStreamTypeLive,
    /**
     *  DVR stream
     */
    SRGMediaPlayerStreamTypeDVR,
};

/**
 *  Playback states
 */
typedef NS_ENUM(NSInteger, SRGMediaPlayerPlaybackState) {
    /**
     *  The player is idle. This state occurs after the player has been initialized, reset, or when an error has been
     *  encountered
     */
    SRGMediaPlayerPlaybackStateIdle,
    /**
     *  The player is preparing to play a media
     */
    SRGMediaPlayerPlaybackStatePreparing,
    /**
     *  A media is being played
     */
    SRGMediaPlayerPlaybackStatePlaying,
    /**
     *  The player is seeking to another position
     */
    SRGMediaPlayerPlaybackStateSeeking,
    /**
     *  The player is paused
     */
    SRGMediaPlayerPlaybackStatePaused,
    /**
     *  The player is stalled, i.e. waiting for media playback to restart (most probably because of poor networking
     *  conditions)
     */
    SRGMediaPlayerPlaybackStateStalled,
    /**
     *  The player has reached the end of the media and has automatically stopped playback
     */
    SRGMediaPlayerPlaybackStateEnded,
};

/**
 *  Notification sent when the player state changes. Use the `SRGMediaPlayerPreviousPlaybackStateKey` to retrieve
 *  previous state information from the notification `userInfo` dictionary
 */
OBJC_EXTERN NSString * const SRGMediaPlayerPlaybackStateDidChangeNotification;              // Notification name
OBJC_EXTERN NSString * const SRGMediaPlayerPlaybackStateKey;                                // Key to access the current playback state as an `NSNumber` (wrapping an `SRGMediaPlayerPlaybackState` value)
OBJC_EXTERN NSString * const SRGMediaPlayerPreviousPlaybackStateKey;                        // Key to access the previous playback state as an `NSNumber` (wrapping an `SRGMediaPlayerPlaybackState` value)
OBJC_EXTERN NSString * const SRGMediaPlayerPreviousContentURLKey;                           // Key to access the previously played URL if it changed
OBJC_EXTERN NSString * const SRGMediaPlayerPreviousUserInfoKey;                             // Key to access the previous user information if it changed

/**
 *  Notification sent when playback failed. Use the `SRGMediaPlayerErrorKey` to retrieve an `NSError` 
 *  information from the notification `userInfo` dictionary)
 */
OBJC_EXTERN NSString * const SRGMediaPlayerPlaybackDidFailNotification;                     // Notification name
OBJC_EXTERN NSString * const SRGMediaPlayerErrorKey;                                        // Key to access error information

/**
 *  Notification sent just before a seek is made (the player is already in the seeking state, though). Use the `SRGMediaPlayerSeekTimeKey`
 *  to retrieve an `NSValue` containing the `CMTime` of the target seek position
 */
OBJC_EXTERN NSString * const SRGMediaPlayerSeekNotification;                                // Notification name
OBJC_EXTERN NSString * const SRGMediaPlayerSeekTimeKey;                                     // Key to access the time to which the seek is made, as an `NSValue` (wrapping a `CMTime` value)

/**
 *  Notification sent when the picture in picture state changes
 */
OBJC_EXTERN NSString * const SRGMediaPlayerPictureInPictureStateDidChangeNotification;

/**
 *  Notification sent when the current segment changes. Use the keys available below to retrieve information from
 *  the notification `userInfo`dictionary
 */
OBJC_EXTERN NSString * const SRGMediaPlayerSegmentDidStartNotification;                     // Notification sent when a segment starts
OBJC_EXTERN NSString * const SRGMediaPlayerSegmentDidEndNotification;                       // Notification sent when a segment ends

// Blocked segments skipping notifications
OBJC_EXTERN NSString * const SRGMediaPlayerWillSkipBlockedSegmentNotification;              // Notification sent when the player starts skipping a blocked segment
OBJC_EXTERN NSString * const SRGMediaPlayerDidSkipBlockedSegmentNotification;               // Notification sent when the player finishes skipping a blocked segment

// Information available for all segment-related notifications
OBJC_EXTERN NSString * const SRGMediaPlayerSegmentKey;                                      // The involved segment as an id<SRGSegment> object

// Information available for `SRGMediaPlayerSegmentDidStartNotification` and `SRGMediaPlayerSegmentDidEndNotification`
OBJC_EXPORT NSString * const SRGMediaPlayerSelectedKey;                                     // Key to an `NSNumber` wrapping a boolean, set to YES iff the segment was selected

// Information available for `SRGMediaPlayerSegmentDidStartNotification`
OBJC_EXTERN NSString * const SRGMediaPlayerPreviousSegmentKey;                              // The previously played segment, if any, as an id<SRGSegment> object

// Information available for `SRGMediaPlayerSegmentDidEndNotification`
OBJC_EXTERN NSString * const SRGMediaPlayerNextSegmentKey;                                  // The previously played segment, if any, as an id<SRGSegment> object

// Information available for `SRGMediaPlayerSegmentDidStartNotification`, `SRGMediaPlayerSegmentDidEndNotification` and `SRGMediaPlayerPlaybackStateDidChangeNotification`
OBJC_EXTERN NSString * const SRGMediaPlayerSelectionKey;                                    // Key to an `NSNumber` wrapping a boolean, set to YES iff the notification results from a segment selection

NS_ASSUME_NONNULL_END
