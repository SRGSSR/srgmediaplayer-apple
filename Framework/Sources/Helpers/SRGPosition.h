//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Representation of a position in time to reach within a given tolerance. In general, a small tolerance means greater
 *  precision, at the expense of efficiency (reaching a position precisely may require more buffering). Conversely,
 *  a large tolerance means less precision, but more efficiency (an acceptable position might require less buffering
 *  to be reached).
 *
 *  Positions are either time-based or date-based. Date-based positions are only relevant for livestreams and are ignored
 *  when used with on-demand ones (in such cases, the default position is used instead).
 *
 *  Remark: When designating a position to within a segment, there is no need to adjust tolerances based on the segment
 *          time range. In such cases, SRG Media Player ensures that the position stays within the desired segment.
 */
@interface SRGPosition : NSObject

/**
 *  The default position.
 */
@property (class, nonatomic, readonly) SRGPosition *defaultPosition;

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
 *  Position earlier than the specified time.
 */
+ (SRGPosition *)positionBeforeTime:(CMTime)time;

/**
 *  Position earlier than the specified time (in seconds).
 */
+ (SRGPosition *)positionBeforeTimeInSeconds:(NSTimeInterval)timeInSeconds;

/**
 *  Position earlier than the specified date.
 */
+ (SRGPosition *)positionBeforeDate:(NSDate *)date;

/**
 *  Position later than the specified time.
 */
+ (SRGPosition *)positionAfterTime:(CMTime)time;

/**
 *  Position later than the specified time (in seconds).
 */
+ (SRGPosition *)positionAfterTimeInSeconds:(NSTimeInterval)timeInSeconds;

/**
 *  Position later than the specified date.
 */
+ (SRGPosition *)positionAfterDate:(NSDate *)date;

/**
 *  Position for the specified time with custom tolerance settings.
 */
+ (SRGPosition *)positionWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;

/**
 *  Position for the specified date with custom tolerance settings.
 */
+ (SRGPosition *)positionWithDate:(NSDate *)date toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;

/**
 *  Instantiate a position for the specified time with custom tolerance settings.
 *
 *  @param time            The position time. Use `kCMTimeZero` for the default position.
 *  @param toleranceBefore The tolerance (before `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 *  @param toleranceAfter  The tolerance (after `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 *
 *  @discussion Invalid times are set to `kCMTimeZero`.
 */
- (instancetype)initWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;

/**
 *  Instantiate a position for the specified date with custom tolerance settings.
 *
 *  @param date            The position date. Use `nil` for the default position.
 *  @param toleranceBefore The tolerance (before `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 *  @param toleranceAfter  The tolerance (after `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 *
 *  @discussion Invalid times are set to `kCMTimeZero`.
 */
- (instancetype)initWithDate:(NSDate *)date toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;

/**
 *  The associated time. Guaranteed to be valid.
 *
 *  @discussion `kCMTimeZero` when a date has been specified.
 */
@property (nonatomic, readonly) CMTime time;

/**
 *  The associated date, if any.
 */
@property (nonatomic, readonly, nullable) NSDate *date;

/**
 *  The tolerances applied when reaching the position. Guaranteed to be valid.
 */
@property (nonatomic, readonly) CMTime toleranceBefore;
@property (nonatomic, readonly) CMTime toleranceAfter;

@end

NS_ASSUME_NONNULL_END
