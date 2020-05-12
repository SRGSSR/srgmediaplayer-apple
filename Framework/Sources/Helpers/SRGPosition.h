//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMark.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Representation of a position to reach within a given tolerance. A position is a time or date, whose duality can
 *  in general be expressed with a mark.
 *
 *  In general, attempting to reach a position with small tolerance means greater precision, at the expense of efficiency
 *  (reaching a position precisely may require more buffering). Conversely, a large tolerance means less precision, but
 *  more efficiency (an acceptable position might require less buffering to be reached).
 *
 *  Remark: When designating a position within a segment, there is no need to adjust tolerances based on the segment
 *          time range. In such cases, SRG Media Player ensures that the position stays within the desired segment.
 */
@interface SRGPosition : NSObject

/**
 *  The default position.
 */
@property (class, nonatomic, readonly) SRGPosition *defaultPosition;

/**
 *  Position for the specified time with custom tolerance settings.
 *
 *  @param time            The position time. Use `kCMTimeZero` for the default position.
 *  @param toleranceBefore The tolerance (before `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 *  @param toleranceAfter  The tolerance (after `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 *
 *  @discussion Invalid times are set to `kCMTimeZero`.
 */
+ (SRGPosition *)positionWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;

/**
 *  Position for the specified date with custom tolerance settings.
 *
 *  @param date            The position date. Use `nil` for the default position.
 *  @param toleranceBefore The tolerance (before `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 *  @param toleranceAfter  The tolerance (after `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 *
 *  @discussion Invalid times are set to `kCMTimeZero`.
 */
+ (SRGPosition *)positionWithDate:(NSDate *)date toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;

/**
 *  Position for the specified mark with custom tolerance settings.
 *
 *  @param mark            The position mark. Use `nil` for the default position.
 *  @param toleranceBefore The tolerance (before `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 *  @param toleranceAfter  The tolerance (after `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 *
 *  @discussion Invalid times are set to `kCMTimeZero`.
 */
+ (SRGPosition *)positionWithMark:(SRGMark *)mark toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;

/**
 *  The associated mark.
 */
@property (nonatomic, readonly) SRGMark *mark;

/**
 *  The tolerances applied when reaching the position. Guaranteed to be valid.
 */
@property (nonatomic, readonly) CMTime toleranceBefore;
@property (nonatomic, readonly) CMTime toleranceAfter;

@end

@interface SRGPosition (Exact)

/**
 *  Exact position at the specified time.
 */
+ (SRGPosition *)positionAtTime:(CMTime)time;

/**
 *  Exact position at the specified time (in seconds).
 */
+ (SRGPosition *)positionAtTimeInSeconds:(NSTimeInterval)timeInSeconds;

/**
 *  Exact position at the specified date.
 */
+ (SRGPosition *)positionAtDate:(NSDate *)date;

/**
 *  Exact position at the specified mark.
 */
+ (SRGPosition *)positionAtMark:(SRGMark *)mark;

@end

@interface SRGPosition (Around)

/**
 *  Position around the specified time with maximum tolerance.
 */
+ (SRGPosition *)positionAroundTime:(CMTime)time;

/**
 *  Position around the specified time with maximum tolerance.
 */
+ (SRGPosition *)positionAroundTimeInSeconds:(NSTimeInterval)timeInSeconds;

/**
 *  Position around the specified date.
 */
+ (SRGPosition *)positionAroundDate:(NSDate *)date;

/**
 *  Position around the specified mark.
 */
+ (SRGPosition *)positionAroundMark:(SRGMark *)mark;

@end

@interface SRGPosition (Before)

/**
 *  Position before the specified time.
 */
+ (SRGPosition *)positionBeforeTime:(CMTime)time;

/**
 *  Position before the specified time (in seconds).
 */
+ (SRGPosition *)positionBeforeTimeInSeconds:(NSTimeInterval)timeInSeconds;

/**
 *  Position before the specified date.
 */
+ (SRGPosition *)positionBeforeDate:(NSDate *)date;

/**
 *  Position before the specified mark.
 */
+ (SRGPosition *)positionBeforeMark:(SRGMark *)mark;

@end

@interface SRGPosition (After)

/**
 *  Position after the specified time.
 */
+ (SRGPosition *)positionAfterTime:(CMTime)time;

/**
 *  Position after the specified time (in seconds).
 */
+ (SRGPosition *)positionAfterTimeInSeconds:(NSTimeInterval)timeInSeconds;

/**
 *  Position after the specified date.
 */
+ (SRGPosition *)positionAfterDate:(NSDate *)date;

/**
 *  Position after the specified mark.
 */
+ (SRGPosition *)positionAfterMark:(SRGMark *)mark;

@end

NS_ASSUME_NONNULL_END
