//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerConstants.h"

NSString * const SRGMediaPlayerUserInfoStreamOffsetKey = @"SRGMediaPlayerUserInfoStreamOffset";

NSString * const SRGMediaPlayerPlaybackStateDidChangeNotification = @"SRGMediaPlayerPlaybackStateDidChangeNotification";

NSString * const SRGMediaPlayerPlaybackDidFailNotification = @"SRGMediaPlayerPlaybackDidFailNotification";

NSString * const SRGMediaPlayerSeekNotification = @"SRGMediaPlayerSeekNotification";

NSString * const SRGMediaPlayerPictureInPictureStateDidChangeNotification = @"SRGMediaPlayerPictureInPictureStateDidChangeNotification";

NSString * const SRGMediaPlayerExternalPlaybackStateDidChangeNotification = @"SRGMediaPlayerExternalPlaybackStateDidChangeNotification";

NSString * const SRGMediaPlayerAudioTrackDidChangeNotification = @"SRGMediaPlayerAudioTrackDidChangeNotification";
NSString * const SRGMediaPlayerSubtitleTrackDidChangeNotification = @"SRGMediaPlayerSubtitleTrackDidChangeNotification";

NSString * const SRGMediaPlayerSegmentDidStartNotification = @"SRGMediaPlayerSegmentDidStartNotification";
NSString * const SRGMediaPlayerSegmentDidEndNotification = @"SRGMediaPlayerSegmentDidEndNotification";

NSString * const SRGMediaPlayerWillSkipBlockedSegmentNotification = @"SRGMediaPlayerWillSkipBlockedSegmentNotification";
NSString * const SRGMediaPlayerDidSkipBlockedSegmentNotification = @"SRGMediaPlayerDidSkipBlockedSegmentNotification";

NSString * const SRGMediaPlayerPlaybackStateKey = @"SRGMediaPlayerPlaybackState";
NSString * const SRGMediaPlayerPreviousPlaybackStateKey = @"SRGMediaPlayerPreviousPlaybackState";
NSString * const SRGMediaPlayerPreviousContentURLKey = @"SRGMediaPlayerPreviousContentURL";
NSString * const SRGMediaPlayerPreviousURLAssetKey = @"SRGMediaPlayerPreviousPlayerItem";
NSString * const SRGMediaPlayerPreviousTimeRangeKey = @"SRGMediaPlayerPreviousTimeRange";
NSString * const SRGMediaPlayerPreviousMediaTypeKey = @"SRGMediaPlayerPreviousMediaType";
NSString * const SRGMediaPlayerPreviousStreamTypeKey = @"SRGMediaPlayerPreviousStreamType";
NSString * const SRGMediaPlayerPreviousUserInfoKey = @"SRGMediaPlayerPreviousUserInfo";
NSString * const SRGMediaPlayerPreviousSelectedSegmentKey = @"SRGMediaPlayerPreviousSelectedSegment";

NSString * const SRGMediaPlayerErrorKey = @"SRGMediaPlayerError";

NSString * const SRGMediaPlayerSeekTimeKey = @"SRGMediaPlayerSeekTime";
NSString * const SRGMediaPlayerSeekDateKey = @"SRGMediaPlayerSeekDate";

NSString * const SRGMediaPlayerSegmentKey = @"SRGMediaPlayerSegment";

NSString * const SRGMediaPlayerSelectedKey = @"SRGMediaPlayerSelected";

NSString * const SRGMediaPlayerPreviousSegmentKey = @"SRGMediaPlayerPreviousSegment";

NSString * const SRGMediaPlayerNextSegmentKey = @"SRGMediaPlayerNextSegment";
NSString * const SRGMediaPlayerInterruptionKey = @"SRGMediaPlayerInterruption";

NSString * const SRGMediaPlayerSelectionKey = @"SRGMediaPlayerSelection";
NSString * const SRGMediaPlayerSelectionReasonKey = @"SRGMediaPlayerSelectionReason";

NSString * const SRGMediaPlayerTrackKey = @"SRGMediaPlayerTrack";
NSString * const SRGMediaPlayerPreviousTrackKey = @"SRGMediaPlayerPreviousTrack";

NSString * const SRGMediaPlayerLastPlaybackTimeKey = @"SRGMediaPlayerLastPlaybackTime";
NSString * const SRGMediaPlayerLastPlaybackDateKey = @"SRGMediaPlayerLastPlaybackDate";

CMTime SRGMediaPlayerEffectiveEndTolerance(NSTimeInterval endTolerance, float endToleranceRatio, NSTimeInterval contentDuration)
{
    if (endTolerance != 0. && endToleranceRatio != 0.f) {
        return CMTimeMinimum(CMTimeMakeWithSeconds(endTolerance, NSEC_PER_SEC),
                             CMTimeMakeWithSeconds(endToleranceRatio * contentDuration, NSEC_PER_SEC));
    }
    else if (endTolerance != 0.) {
        return CMTimeMakeWithSeconds(endTolerance, NSEC_PER_SEC);
    }
    else if (endToleranceRatio != 0.f) {
        return CMTimeMakeWithSeconds(endToleranceRatio * contentDuration, NSEC_PER_SEC);
    }
    else {
        return kCMTimeZero;
    }
}
