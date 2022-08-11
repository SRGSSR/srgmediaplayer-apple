//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import CoreMedia;
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  @name Tolerances
 */

// Default amount of seconds at the end of a DVR stream assumed to correspond to live conditions (same tolerance as the built-in iOS player).
static NSTimeInterval const SRGMediaPlayerDefaultLiveTolerance = 30.;

// Default absolute tolerance applied when attempting to play a stream (or segment thereof) starting near its end.
static NSTimeInterval const SRGMediaPlayerDefaultEndTolerance = 0.;

// Default relative tolerance applied when attempting to play a stream (or segment thereof) starting near its end.
static float const SRGMediaPlayerDefaultEndToleranceRatio = 0.f;

/**
 *  Calculate the effective end tolerance applied for an absolute and relative tolerance, for a content having the provided duration.
 */
OBJC_EXPORT CMTime SRGMediaPlayerEffectiveEndTolerance(NSTimeInterval endTolerance, float endToleranceRatio, NSTimeInterval contentDuration);

/**
 *  @name Types
 */

/**
 *  Background view behavior.
 */
typedef NS_ENUM(NSInteger, SRGMediaPlayerViewBackgroundBehavior) {
    /**
     *  Keep the player view attached to the controller in background.
     */
    SRGMediaPlayerViewBackgroundBehaviorAttached = 0,
    /**
     *  Detach the player view from the controller in background.
     */
    SRGMediaPlayerViewBackgroundBehaviorDetached,
    /**
     *  Detach the player view from the controller when the device is locked while the application is still open.
     */
    SRGMediaPlayerViewBackgroundBehaviorDetachedWhenDeviceLocked API_UNAVAILABLE(tvos)
};

/**
 *  Media types.
 */
typedef NS_ENUM(NSInteger, SRGMediaPlayerMediaType) {
    /**
     *  Unknown type.
     */
    SRGMediaPlayerMediaTypeUnknown = 0,
    /**
     *  Video.
     */
    SRGMediaPlayerMediaTypeVideo,
    /**
     *  Audio.
     */
    SRGMediaPlayerMediaTypeAudio
};

/**
 *  Stream types.
 */
typedef NS_ENUM(NSInteger, SRGMediaPlayerStreamType) {
    /**
     *  Unknown type.
     */
    SRGMediaPlayerStreamTypeUnknown = 0,
    /**
     *  On-demand stream.
     */
    SRGMediaPlayerStreamTypeOnDemand,
    /**
     *  Live stream.
     */
    SRGMediaPlayerStreamTypeLive,
    /**
     *  DVR stream.
     */
    SRGMediaPlayerStreamTypeDVR
};

/**
 *  Playback states.
 */
typedef NS_ENUM(NSInteger, SRGMediaPlayerPlaybackState) {
    /**
     *  The player is idle. This state occurs after the player has been initialized, reset, or when an error has been
     *  encountered.
     */
    SRGMediaPlayerPlaybackStateIdle = 1,
    /**
     *  The player is preparing to play a media.
     */
    SRGMediaPlayerPlaybackStatePreparing,
    /**
     *  A media is being played.
     */
    SRGMediaPlayerPlaybackStatePlaying,
    /**
     *  The player is seeking to another position.
     */
    SRGMediaPlayerPlaybackStateSeeking,
    /**
     *  The player is paused.
     */
    SRGMediaPlayerPlaybackStatePaused,
    /**
     *  The player is stalled, i.e. waiting for media playback to resume (most probably because of poor networking
     *  conditions).
     */
    SRGMediaPlayerPlaybackStateStalled,
    /**
     *  The player has reached the end of the media and has automatically stopped playback.
     */
    SRGMediaPlayerPlaybackStateEnded
};

/**
 *  Reasons for segment selection.
 */
typedef NS_ENUM(NSInteger, SRGMediaPlayerSelectionReason) {
    SRGMediaPlayerSelectionReasonInitial = 1,                   // Initial selection at playback start
    SRGMediaPlayerSelectionReasonUpdate                         // Selection update during playback
};

/**
 *  @name Playback setup (provided as `userInfo` to the controller).
 */

/**
 *  `SRGMediaPlayerController` supports seeking to dates for livestreams with DVR support. It is strongly recommended
 *  that date information is delivered within HLS streams to support accurate positioning. If date information is not
 *  embedded in the streams, though, the position is approximated based on the device date.
 *
 *  We cannot do much against devices off-clock but, even assuming that your device is synchronized with a time server,
 *  you might still experience delays when seeking to a date in a stream which does not embedd timestamps. This is
 *  due to stream encoding and delivery, which creates a delay in comparison to usual broadcasting.
 *
 *  To compensate for such effects, you can provide an offset as an `NSValue` wrapping a `CMTime`, giving the offset
 *  you experience from theoretically perfect delivery. For example, if you seek to a date where you expect to hear
 *  something, but in fact must wait 1 minute before hearing what you were expecting, set this time to 1 minute.
 *
 *  If date information is available within the stream, if the streams is not a livestream with DVR capabilities,
 *  or if the time is incorrect (negative or invalid), this value is ignored.
 *
 *  @discussion The behavior is undefined if you attempt to update this value during playback.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerUserInfoStreamOffsetKey;

/**
 *  @name Notifications
 */

/**
 *  Notification sent when the player state changes.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerPlaybackStateDidChangeNotification;              // Notification name.

/**
 *  Notification sent when playback failed. Use the `SRGMediaPlayerErrorKey` to retrieve an `NSError` information 
 *  from the notification `userInfo` dictionary).
 */
OBJC_EXPORT NSString * const SRGMediaPlayerPlaybackDidFailNotification;                     // Notification name.

/**
 *  Notification sent just before a seek is made (the player is already in the seeking state, though). Use the `SRGMediaPlayerSeekTimeKey`
 *  to retrieve an `NSValue` containing the `CMTime` of the target seek position, or `SRGMediaPlayerSeekDateKey` for a date position if
 *  the stream supports date seeking.
 *
 *  @discussion If multiple seeks are made, no additional state change notification is sent (and thus the new target seek
 *              time is not received in a notification).
 */
OBJC_EXPORT NSString * const SRGMediaPlayerSeekNotification;                                // Notification name.

/**
 *  Notification sent when the picture in picture state changes.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerPictureInPictureStateDidChangeNotification;

/**
 *  Notification sent when the external playback is enabled or disabled.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerExternalPlaybackStateDidChangeNotification;

/**
 *  Notification sent when tracks changed. Use the keys available below to retrieve information from the notification
 *  `userInfo` dictionary.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerAudioTrackDidChangeNotification;
OBJC_EXPORT NSString * const SRGMediaPlayerSubtitleTrackDidChangeNotification;

/**
 *  Notification sent when the current segment changes. Use the keys available below to retrieve information from
 *  the notification `userInfo` dictionary.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerSegmentDidStartNotification;                     // Notification sent when a segment starts.
OBJC_EXPORT NSString * const SRGMediaPlayerSegmentDidEndNotification;                       // Notification sent when a segment ends.

/**
 *  Blocked segments skipping notifications.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerWillSkipBlockedSegmentNotification;              // Notification sent when the player starts skipping a blocked segment.
OBJC_EXPORT NSString * const SRGMediaPlayerDidSkipBlockedSegmentNotification;               // Notification sent when the player finishes skipping a blocked segment.

/**
 *  @name Notification user information keys
 */

/**
 *  Information available for `SRGMediaPlayerPlaybackStateDidChangeNotification`.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerPlaybackStateKey;                                // Key to access the current playback state as an `NSNumber` (wrapping an `SRGMediaPlayerPlaybackState` value).
OBJC_EXPORT NSString * const SRGMediaPlayerPreviousPlaybackStateKey;                        // Key to access the previous playback state as an `NSNumber` (wrapping an `SRGMediaPlayerPlaybackState` value).
OBJC_EXPORT NSString * const SRGMediaPlayerPreviousContentURLKey;                           // Key to access the previously played URL.
OBJC_EXPORT NSString * const SRGMediaPlayerPreviousURLAssetKey;                             // Key to access the previously played `AVURLAsset`.
OBJC_EXPORT NSString * const SRGMediaPlayerPreviousTimeRangeKey;                            // Key to access the previous time range as an `NSValue` (wrapping an `CMTimeRange` value).
OBJC_EXPORT NSString * const SRGMediaPlayerPreviousMediaTypeKey;                            // Key to access the previous media type as an `NSNumber` (wrapping an `SRGMediaPlayerMediaType` value).
OBJC_EXPORT NSString * const SRGMediaPlayerPreviousStreamTypeKey;                           // Key to access the previous stream type as an `NSNumber` (wrapping an `SRGMediaPlayerStreamType` value).
OBJC_EXPORT NSString * const SRGMediaPlayerPreviousUserInfoKey;                             // Key to access the previous user information.
OBJC_EXPORT NSString * const SRGMediaPlayerPreviousSelectedSegmentKey;                      // Key to access the previously selected segment as an `id<SRGSegment>` object, if any.

/**
 *  Information available for `SRGMediaPlayerPlaybackDidFailNotification`.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerErrorKey;                                        // Key to access error information.

/**
 *  Information available for `SRGMediaPlayerSeekNotification`.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerSeekTimeKey;                                     // Key to access the time to which the seek is made, as an `NSValue` (wrapping a `CMTime` value).
OBJC_EXPORT NSString * const SRGMediaPlayerSeekDateKey;                                     // Key to access the date to which the seek is made, as an `NSDate`. For DVR streams only.

/**
 *  Information available for all segment-related notifications.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerSegmentKey;                                      // The involved segment as an `id<SRGSegment>` object.

/**
 *  Information available for `SRGMediaPlayerSegmentDidStartNotification` and `SRGMediaPlayerSegmentDidEndNotification`.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerSelectedKey;                                     // Key to an `NSNumber` wrapping a boolean, set to `YES` iff the segment was selected.

/**
 *  Information available for `SRGMediaPlayerSegmentDidStartNotification`.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerPreviousSegmentKey;                              // The previously played segment, if any, as an `id<SRGSegment>` object.

/**
 *  Information available for `SRGMediaPlayerSegmentDidEndNotification`.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerNextSegmentKey;                                  // The segment which will be played next, if any, as an `id<SRGSegment>` object.
OBJC_EXPORT NSString * const SRGMediaPlayerInterruptionKey;                                 // Key to an `NSNumber` wrapping a boolean, set to `YES` iff the end notification results because segment playback was interrupted.

/**
 *  Information available for `SRGMediaPlayerSegmentDidStartNotification`, `SRGMediaPlayerSegmentDidEndNotification` and `SRGMediaPlayerPlaybackStateDidChangeNotification`.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerSelectionKey;                                    // Key to an `NSNumber` wrapping a boolean, set to `YES` iff the notification results from a segment selection.
OBJC_EXPORT NSString * const SRGMediaPlayerSelectionReasonKey;                              // Key to an `NSNumber` wrapping a `SRGMediaPlayerSelectionReason`, specifying the reason selection was made.

/**
 *  Information available for `SRGMediaPlayerAudioTrackDidChangeNotification` and `SRGMediaPlayerSubtitleTrackDidChangeNotification`.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerTrackKey;                                       // Key to the current `AVMediaSelectionOption`.
OBJC_EXPORT NSString * const SRGMediaPlayerPreviousTrackKey;                               // Key to the previous `AVMediaSelectionOption`.

/**
 *  Information available for all notifications, except `SRGMediaPlayerPictureInPictureStateDidChangeNotification` and `SRGMediaPlayerExternalPlaybackStateDidChangeNotification`.
 *  For `SRGMediaPlayerPlaybackStateDidChangeNotification` notifications, this key is only present when the player returns to idle, and provides the last known playback position.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerLastPlaybackTimeKey;                             // Key to an `NSValue` wrapping a `CMTime` specifying the last playback position before the event occurred.
OBJC_EXPORT NSString * const SRGMediaPlayerLastPlaybackDateKey;                             // Key to an `NSDate` specifying the last playback date before the event occurred. For DVR streams only.

NS_ASSUME_NONNULL_END
