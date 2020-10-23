//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CMTime+SRGMediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  `CMTIMERANGE_IS_EMPTY` cannot be tested negatively (gives false positives for invalid ranges). Use this macro instead.
 */
#define SRG_CMTIMERANGE_IS_NOT_EMPTY(range) ((Boolean)(CMTIMERANGE_IS_VALID(range) && (CMTIME_COMPARE_INLINE(range.duration, !=, kCMTimeZero))))

/**
 *  `CMTIMERANGE_IS_INDEFINITE` cannot be tested negatively (gives false positives for invalid ranges). Use this macro instead.
 */
#define SRG_CMTIMERANGE_IS_DEFINITE(range) ((Boolean)(CMTIMERANGE_IS_VALID(range) && SRG_CMTIME_IS_DEFINITE(range.start) && SRG_CMTIME_IS_DEFINITE(range.duration)))

NS_ASSUME_NONNULL_END
