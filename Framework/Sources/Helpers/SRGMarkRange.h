//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMark.h"

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGMediaPlayerController;

/**
 *  Describes a range enclosed by two marks.
 */
@interface SRGMarkRange : NSObject

/**
 *  Range between the two specified marks.
 */
+ (SRGMarkRange *)rangeFromMark:(SRGMark *)fromMark toMark:(SRGMark *)toMark;

/**
 *  Range end marks.
 */
@property (nonatomic, readonly) SRGMark *fromMark;
@property (nonatomic, readonly) SRGMark *toMark;

@end

@interface SRGMarkRange (Convenience)

/**
 *  Range between two times.
 */
+ (SRGMarkRange *)rangeFromTime:(CMTime)fromTime toTime:(CMTime)toTime;

/**
 *  Range between two times in seconds.
 */
+ (SRGMarkRange *)rangeFromTimeInSeconds:(NSTimeInterval)fromTimeInSeconds toTimeInSeconds:(NSTimeInterval)toTimeInSeconds;

/**
 *  Range from a time range.
 */
+ (SRGMarkRange *)rangeFromTimeRange:(CMTimeRange)timeRange;

/**
 *  Range between two dates.
 */
+ (SRGMarkRange *)rangeFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

@end

@interface SRGMarkRange (TimeConversions)

/**
 *  Return the time corresponding to a mark, in the reference frame of the provided controller.
 *
 *  @discussion Returns the raw time range if the controller is `nil`.
 */
- (CMTimeRange)timeRangeForMediaPlayerController:(nullable SRGMediaPlayerController *)mediaPlayerController;

@end

NS_ASSUME_NONNULL_END
