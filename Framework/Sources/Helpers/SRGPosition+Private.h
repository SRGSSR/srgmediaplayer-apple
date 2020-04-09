//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPosition.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Private interface for implementation purposes.
 */
@interface SRGPosition (Private)

/**
 *  The associated time. Guaranteed to be valid.
 *
 *  @discussion `kCMTimeZero` when if the mark is a date.
 */
@property (nonatomic, readonly) CMTime time;

/**
 *  The mark date, if any.
 */
@property (nonatomic, readonly, nullable) NSDate *date;

@end

NS_ASSUME_NONNULL_END
