//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import CoreMedia;

NS_ASSUME_NONNULL_BEGIN

/**
 *  `CMTIME_IS_INDEFINTE` cannot be tested negatively (gives false positives for invalid times). Use this macro instead.
 */
#define SRG_CMTIME_IS_DEFINITE(time) ((Boolean)(CMTIME_IS_VALID(time) && (((time).flags & kCMTimeFlags_Indefinite) == 0)))

NS_ASSUME_NONNULL_END
