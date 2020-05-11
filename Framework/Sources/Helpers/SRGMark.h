//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGMediaPlayerController;

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

/**
 *  The mark date, if any.
 */
@property (nonatomic, readonly, nullable) NSDate *date;

@end

@interface SRGMark (TimeConversions)

/**
 *  Return the time corresponding to a mark, in the reference frame of the provided controller.
 *
 *  @discussion Returns the raw time if the controller is `nil`.
 */
- (CMTime)timeForMediaPlayerController:(nullable SRGMediaPlayerController *)mediaPlayerController;

@end

NS_ASSUME_NONNULL_END
