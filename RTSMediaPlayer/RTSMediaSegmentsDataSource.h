//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>

@class RTSMediaSegmentsController;
@protocol RTSMediaSegment;

typedef void (^RTSMediaSegmentsCompletionHandler)(id<RTSMediaSegment> fullLength, NSArray *segments, NSError *error);

@protocol RTSMediaSegmentsDataSource <NSObject>

- (void)segmentsController:(RTSMediaSegmentsController *)controller
	 segmentsForIdentifier:(NSString *)identifier
	 withCompletionHandler:(RTSMediaSegmentsCompletionHandler)completionHandler;

@end
