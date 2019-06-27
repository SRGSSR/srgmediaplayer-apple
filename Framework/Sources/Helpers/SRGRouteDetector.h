//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Notification sent when wireless routes change (e.g. AirPlay enabled or disabled).
 */
OBJC_EXPORT NSString * const SRGMediaPlayerWirelessRoutesAvailableDidChangeNotification;

/**
 *  Detect route availability (e.g. Bluetooth or AirPlay). Similar to `AVRouteDetector`, but available for iOS 10
 *  and below as well.
 */
@interface SRGRouteDetector : NSObject

/**
 *  Shared singleton instance.
 */
@property (class, nonatomic, readonly) SRGRouteDetector *sharedRouteDetector;

/**
 *  Returns `YES` iff routes are available.
 */
@property (nonatomic, readonly) BOOL multipleRoutesDetected;

@end

NS_ASSUME_NONNULL_END
