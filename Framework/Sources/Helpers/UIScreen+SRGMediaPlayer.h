//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

/**
 *  Extensions to `UIScreen`.
 */
@interface UIScreen (SRGMediaPlayer)

/**
 *  Return `YES` iff any screen is currently being mirrored.
 *
 *  @discussion You can listen to the `UIScreenDidConnectNotification` and `UIScreenDidDisconnectNotification` notifications
 *              to detect when mirroring is enabled, respectively disabled.
 */
+ (BOOL)srg_isMirroring;

@end
