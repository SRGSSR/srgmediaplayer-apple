//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerConstants.h"

#import "NSBundle+SRGMediaPlayer.h"

NSTimeInterval const SRGMediaPlayerLiveDefaultTolerance = 30.;                // Same tolerance as the built-in iOS player

NSString * const SRGMediaPlayerPlaybackStateDidChangeNotification = @"SRGMediaPlayerPlaybackStateDidChangeNotification";
NSString * const SRGMediaPlayerPlaybackStateKey = @"SRGMediaPlayerPlaybackStateKey";
NSString * const SRGMediaPlayerPreviousPlaybackStateKey = @"SRGMediaPlayerPreviousPlaybackStateKey";
NSString * const SRGMediaPlayerPreviousContentURLKey = @"SRGMediaPlayerPreviousContentURLKey";
NSString * const SRGMediaPlayerPreviousUserInfoKey = @"SRGMediaPlayerPreviousUserInfoKey";

NSString * const SRGMediaPlayerPlaybackDidFailNotification = @"SRGMediaPlayerPlaybackDidFailNotification";
NSString * const SRGMediaPlayerErrorKey = @"SRGMediaPlayerErrorKey";

NSString * const SRGMediaPlayerSeekNotification = @"SRGMediaPlayerSeekNotification";
NSString * const SRGMediaPlayerSeekTimeKey = @"SRGMediaPlayerSeekTimeKey";

NSString * const SRGMediaPlayerPictureInPictureStateDidChangeNotification = @"SRGMediaPlayerPictureInPictureStateDidChangeNotification";

NSString * const SRGMediaPlayerSegmentDidStartNotification = @"SRGMediaPlayerSegmentDidStartNotification";
NSString * const SRGMediaPlayerSegmentDidEndNotification = @"SRGMediaPlayerSegmentDidEndNotification";

NSString * const SRGMediaPlayerWillSkipBlockedSegmentNotification = @"SRGMediaPlayerWillSkipBlockedSegmentNotification";
NSString * const SRGMediaPlayerDidSkipBlockedSegmentNotification = @"SRGMediaPlayerDidSkipBlockedSegmentNotification";

NSString * const SRGMediaPlayerSegmentKey = @"SRGMediaPlayerSegmentKey";
NSString * const SRGMediaPlayerSelectedKey = @"SRGMediaPlayerSelectedKey";
NSString * const SRGMediaPlayerPreviousSegmentKey = @"SRGMediaPlayerPreviousSegmentKey";
NSString * const SRGMediaPlayerNextSegmentKey = @"SRGMediaPlayerNextSegmentKey";
NSString * const SRGMediaPlayerSelectionKey = @"SRGMediaPlayerSelectionKey";

NSString * SRGMediaPlaybackButtonStopAccessibilityLabel = nil;
NSString * SRGMediaPlaybackButtonGoToLiveAccessibilityLabel = nil;
NSString * SRGMediaPlaybackButtonBackwardAccessibilityLabelFormat = nil;
NSString * SRGMediaPlaybackButtonForwardAccessibilityLabelFormat = nil;

__attribute__((constructor)) static void SRGMediaPlayerConstantsInit(void)
{
    SRGMediaPlaybackButtonStopAccessibilityLabel = SRGMediaPlayerAccessibilityLocalizedString(@"Stop", @"A stop button");
    SRGMediaPlaybackButtonGoToLiveAccessibilityLabel = SRGMediaPlayerAccessibilityLocalizedString(@"Go to live", @"A go to live button");
    SRGMediaPlaybackButtonBackwardAccessibilityLabelFormat = SRGMediaPlayerAccessibilityLocalizedString(@"%@ backward", @"A seek backward button with a custom time range");
    SRGMediaPlaybackButtonForwardAccessibilityLabelFormat = SRGMediaPlayerAccessibilityLocalizedString(@"%@ forward", @"A seek forward button with a custom time range");
}
