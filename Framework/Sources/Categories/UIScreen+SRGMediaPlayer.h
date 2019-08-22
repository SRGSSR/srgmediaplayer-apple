//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

@interface UIScreen (SRGMediaPlayer)

/**
 *  Return `YES` iff any screen is currently being mirrored.
 *
 *  @discussion You can listen to the `UIScreenDidConnectNotification` and `UIScreenDidDisconnectNotification` notifications
 *              to detect when mirroring is enabled, respectively disabled.
 */
@property (class, nonatomic, readonly) BOOL srg_isMirroring API_AVAILABLE(ios(9.0));

@end
