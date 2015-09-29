//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

// Forward declarations
@class RTSMediaSegmentsController;
@protocol RTSMediaSegment;

// Block signatures
typedef void (^RTSMediaSegmentsCompletionHandler)(id<RTSMediaSegment> fullLength, NSArray *segments, NSError *error);

/**
 * Protocol describing how a media segments controller receives the segment information it requires
 */
@protocol RTSMediaSegmentsDataSource <NSObject>

/**
 *  Method called when a segments controller needs to retrieve segment information
 *
 *  @param controller        The segments controller making the request
 *  @param identifier        The identifier for which segments must be retrieved
 *  @param completionHandler The block which the implementation must call to return segments and full-length information 
 *                           to the controller, or an error if it could not be retrieved
 */
- (void)segmentsController:(RTSMediaSegmentsController *)controller
	 segmentsForIdentifier:(NSString *)identifier
	 withCompletionHandler:(RTSMediaSegmentsCompletionHandler)completionHandler;

@end
