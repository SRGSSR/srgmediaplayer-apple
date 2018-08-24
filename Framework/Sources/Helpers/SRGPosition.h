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
 */
@interface SRGPosition : NSObject

/**
 *  The default position.
 */
+ (SRGPosition *)defaultPosition;

/**
 *  Precise position at the specified time.
 */
+ (SRGPosition *)precisePositionAtTime:(CMTime)time;

/**
 *  Imprecise position around the specified time.
 */
+ (SRGPosition *)imprecisePositionAroundTime:(CMTime)time;

/**
 *  Position for the specified time with custom tolerance settings.
 */
+ (SRGPosition *)positionWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;

/**
 *  Instantiate a position for the specified time with custom tolerance settings.
 *
 *  @param time            The position time. Use `kCMTimeZero` for the default position.
 *  @param toleranceBefore The tolerance (before `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 *  @param toleranceBefore The tolerance (after `time`) allowed when reaching the position. Use `kCMTimeZero` for precise
 *                         positioning, or `kCMTimePositiveInfinity` for efficient positioning.
 */
- (instancetype)initWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;

/**
 *  The time to reach.
 */
@property (nonatomic, readonly) CMTime time;

/**
 *  The tolerances applied when reaching `time`.
 */
@property (nonatomic, readonly) CMTime toleranceBefore;
@property (nonatomic, readonly) CMTime toleranceAfter;

@end

NS_ASSUME_NONNULL_END
