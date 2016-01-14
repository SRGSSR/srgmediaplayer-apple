//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import "RTSMediaPlayerConstants.h"
#import "RTSMediaPlayerController.h"

// Forward declarations
@protocol RTSMediaSegment;
@protocol RTSMediaSegmentsDataSource;

/**
 *  A segments controller mediates playback managed by a media player controller according to a list of segments
 *  it retrieves from a data source. Segments can either be blocked or visible, and the segments controller is responsible
 *  of skipping blocked segments or blocking access to them when seeking.
 *
 *  When a data source is requested for segments, it might return segments with other identifiers as well. Segments with the 
 *  same identifiers are treated as logical segments (part of a single media, and sharing its identifier), whereas segments 
 *  with different identifiers are treated as physical segments (separate medias with different identifiers). Segments which
 *  are incorrect (e.g. outside a full-length) are ignored.
 *
 *  For logical segments, the segment controller locates the largest segment and considers it as being the full-length media, 
 *  to which other segments must belong to (segments which would incorrectly not belong to it will be discarded with a warning). 
 *  It them manages playback between them transparently.
 *
 *  For physical segments, switching to another segment changes the media actually played (the previous one is stopped, and
 *  playback is started for the new one). Logical and physical segments can be freely mixed together.
 *
 *  To use a segments controller, instantiate or drop an instance in Interface Builder, and bind it to the underlying
 *  player controller. Also attach a data source from which segments will be retrieved for the media being played. When
 *  segments need to be retrieved, call 'reloadSegementsForIdentifier:completionHandler:'
 *
 *  When controlling playback for a media with segments, call RTSMediaPlayback methods on the segment controller. For
 *  convenience, you can readily display segments as a timeline (see 'RTSSegmentedTimelineView') and / or on top of a
 *  slider (see 'RTSTimelineSlider').
 */
@interface RTSMediaSegmentsController : NSObject

/**
 *  The player controller associated with the segments controller.
 */
@property(nonatomic, weak) IBOutlet RTSMediaPlayerController *playerController;

/**
 *  The data source of the segments controller.
 */
@property(nonatomic, weak) IBOutlet id<RTSMediaSegmentsDataSource> dataSource;

/**
 *  Reload segments data for given media identifier.
 *
 *  @param identifier        The media identifier
 *  @param completionHandler The completion handler.
 */
- (void)reloadSegmentsForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSError *error))completionHandler;

/**
 *  The segments
 *
 *  @return A an array containing the valid segments which were retrieved from the data source.
 */
- (NSArray *)segments;

/**
 *  The visible segments
 *
 *  @return A an array containing the data sources of each episodes.
 */
- (NSArray *)visibleSegments;

/**
 *  The current segment in which the playback head is located.
 *
 *  @return The segment. Returns nil if the position corresponds to no segments.
 */
- (id<RTSMediaSegment>)currentSegment;

/**
 *  Asks the segments controller to play the specified segment intentionally (= user-triggered)
 *
 *  @param time The segment to play
 */
- (void)playSegment:(id<RTSMediaSegment>)segment;

@end

@interface RTSMediaPlayerController (RTSMediaSegmentsController)

/**
 *  Return the segments controller mediating playback for the receiver, nil if none
 */
@property (nonatomic, readonly, weak) RTSMediaSegmentsController *segmentsController;

@end
