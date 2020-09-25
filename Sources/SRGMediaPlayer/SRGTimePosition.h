//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import CoreMedia;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Representation of a time to reach with a given tolerance.
 */
@interface SRGTimePosition : NSObject

/**
 *  The default position.
 */
@property (class, nonatomic, readonly) SRGTimePosition *defaultPosition;

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

+ (SRGTimePosition *)positionWithTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;

/**
 *  The time to reach. Guaranteed to be valid.
 */
@property (nonatomic, readonly) CMTime time;

/**
 *  The tolerances applied when reaching the time. Guaranteed to be valid.
 */
@property (nonatomic, readonly) CMTime toleranceBefore;
@property (nonatomic, readonly) CMTime toleranceAfter;

@end

NS_ASSUME_NONNULL_END
