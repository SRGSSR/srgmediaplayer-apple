//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

#import <SRGMediaPlayer/RTSMediaPlayerConstants.h>
#import <SRGMediaPlayer/RTSMediaSegmentsDataSource.h>

// Forward declarations
@class RTSMediaPlayerController;
@protocol RTSMediaSegment;

/**
 *  A segments controller mediates playback managed by a media player controller according to a list of segments
 *  it retrieves from a data source. Segments can either be blocked or visible, and the segments controller is responsible
 *  of skipping blocked segments or blocking access to them when seeking.
 *
 *  Segments with the same identifiers are treated as logical segments (part of a single media, and sharing its identifier), 
 *  whereas segments with different identifiers are treated as physical segments (separate medias with different identifiers).
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
 * Return YES iff the segment corresponds to a full length
 */
+ (BOOL)isFullLengthSegment:(id<RTSMediaSegment>)segment;

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
 *  @return A an array containing the segments.
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
