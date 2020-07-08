//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAudioSession (SRGMediaPlayer)

/**
 *  Return `YES` iff AirPlay is active (i.e. displaying on an external AirPlay device).
 */
@property (class, nonatomic, readonly) BOOL srg_isAirPlayActive;

/**
 *  Return `YES` iff a Bluetooth headset is being used.
 */
@property (class, nonatomic, readonly) BOOL srg_isBluetoothHeadsetActive;

/**
 *  Return `YES` iff a route is active for the specified port.
 */
+ (BOOL)srg_isRouteActiveForPort:(AVAudioSessionPort)port;

/**
 *  Return the active AirPlay route name if possible, or `nil` when no route is active.
 */
@property (class, nonatomic, readonly, copy, nullable) NSString *srg_activeAirPlayRouteName;

@end

NS_ASSUME_NONNULL_END
