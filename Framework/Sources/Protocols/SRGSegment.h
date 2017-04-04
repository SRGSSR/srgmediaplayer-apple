//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol for formal description of a segment (part of a media).
 */
@protocol SRGSegment <NSObject>

/**
 *  The time range covered by the segment in the associated media.
 */
@property (nonatomic, readonly) CMTimeRange srg_timeRange;

/**
 *  Return `YES` iff the segment can be played. Blocked segments are skipped during playback.
 */
@property (nonatomic, readonly, getter=srg_isBlocked) BOOL srg_blocked;

/**
 *  Return `YES` iff the segment must be hidden (this information can be used by UI overlays to hide segments from
 *  view).
 */
@property (nonatomic, readonly, getter=srg_isHidden) BOOL srg_hidden;

@end

NS_ASSUME_NONNULL_END
