//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Represents a mark within a media, either as a time or a date. Date marks are only relevant for livestreams.
 *  If incorrectly used with an on-demand streams, they are simply interpreted as `kCMTimeZero`.
 */
@interface SRGMark : NSObject

/**
 *  Mark at the specified time.
 */
+ (SRGMark *)markAtTime:(CMTime)time;

/**
 *  Mark at the specified time (in seconds).
 */
+ (SRGMark *)markAtTimeInSeconds:(NSTimeInterval)timeInSeconds;

/**
 *  Mark at the specified date.
 */
+ (SRGMark *)markAtDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
