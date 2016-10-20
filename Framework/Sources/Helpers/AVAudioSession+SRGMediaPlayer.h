//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>

/**
 *  Notification sent when the wireless route changes
 *
 *  @discussion Exactly the same as `MPVolumeViewWirelessRouteActiveDidChangeNotification`, but without the need
 *              for a volume view
 */
OBJC_EXTERN NSString * const SRGMediaPlayerWirelessRouteDidChangeNotification;

/**
 *  Extensions to `AVAudioSession`
 */
@interface AVAudioSession (SRGMediaPlayer)

/**
 *  Returns YES iff Airplay is active (i.e. displaying on an external Airplay device)
 *
 *  @discussion You can listen to the `SRGMediaPlayerWirelessRouteDidChangeNotification` notification to detect route changes
 */
+ (BOOL)srg_isAirplayActive;

@end
