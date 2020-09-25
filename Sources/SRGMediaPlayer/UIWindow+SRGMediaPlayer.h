//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (SRGMediaPlayer)

/**
 *  Return the topmost view controller (either root view controller or presented modally)
 */
@property (nonatomic, readonly) __kindof UIViewController *srg_topViewController;

@end

NS_ASSUME_NONNULL_END
