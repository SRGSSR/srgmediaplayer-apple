//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCTestCase (MediaPlayerTests)

/**
 *  Replacement for `-expectationForNotification:object:handler:`, which suffers from stability issues when running
 *  tests involving seeks (was stable prior to Xcode 8.3).
 *  See https://github.com/SRGSSR/SRGMediaPlayer-iOS/issues/22.
 */
- (XCTestExpectation *)mpt_expectationForNotification:(NSNotificationName)notificationName object:(nullable id)objectToObserve handler:(nullable XCNotificationExpectationHandler)handler;

@end

NS_ASSUME_NONNULL_END
