//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

/**
 *  Protocol formally describing a media segment. A class describing a segment must conform to this protocol and implement
 *  the required methods appropriately. A segment class will in general contain more information (e.g. segment title, thumbnail
 *  URL, etc.), but is not required to
 */
@protocol RTSMediaSegment <NSObject>

/**
 *  Parent segment.
 */
@property (nonatomic, readonly, weak) id<RTSMediaSegment> parent;

/**
 *  Media Segment Identifier
 */
@property (nonatomic, readonly) NSString *segmentIdentifier; // chiote

/**
 *  Segment start and end times (might be identical)
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *  Must return YES iff the segment is blocked (i.e. cannot be played)
 */
@property (nonatomic, readonly, getter=isBlocked) BOOL blocked;

/**
 *  Must return YES iff the segment is visible
 */
@property (nonatomic, readonly, getter=isVisible) BOOL visible;

@end
