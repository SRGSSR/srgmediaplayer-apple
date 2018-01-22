//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGSegment+Private.h"

BOOL SRGMediaPlayerAreEqualSegments(id<SRGSegment> segment1, id<SRGSegment> segment2)
{
    return CMTimeRangeEqual(segment1.srg_timeRange, segment2.srg_timeRange)
        && segment1.srg_blocked == segment2.srg_blocked && segment1.srg_hidden == segment2.srg_hidden;
}
