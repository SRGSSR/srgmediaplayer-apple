//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  `NSDateComponentsFormatter` cannot use NaN or infinity time interval. Use this macro to check.
 */
#define SRG_NSTIMEINTERVAL_IS_VALID(timeInterval) (!isnan(timeInterval) && !isinf(timeInterval))

NS_ASSUME_NONNULL_END
