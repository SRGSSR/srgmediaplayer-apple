//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Notification sent when the wireless route changes.
 *
 *  @discussion Exactly the same as `MPVolumeViewWirelessRouteActiveDidChangeNotification`, but without the need
 *              for a volume view.
 */
OBJC_EXTERN NSString * const SRGMediaPlayerWirelessRouteDidChangeNotification;

@interface AVAudioSession (SRGMediaPlayer)

/**
 *  Returns `YES` iff Airplay is active (i.e. displaying on an external Airplay device).
 *
 *  @discussion You can listen to the `SRGMediaPlayerWirelessRouteDidChangeNotification` notification to detect route changes.
 */
+ (BOOL)srg_isAirplayActive;

/**
 *  Return the active Airplay route name if possible. If no route is active, the method returns `nil`.
 */
+ (nullable NSString *)srg_activeAirplayRouteName;

@end

NS_ASSUME_NONNULL_END
