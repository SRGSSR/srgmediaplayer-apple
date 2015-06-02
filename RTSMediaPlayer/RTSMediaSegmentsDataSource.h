//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RTSMediaSegmentsController;
@protocol RTSMediaPlayerSegment;

typedef void (^RTSMediaSegmentsCompletionHandler)(id<RTSMediaPlayerSegment> fullLength, NSArray *segments, NSError *error);

@protocol RTSMediaSegmentsDataSource <NSObject>

- (void)segmentsController:(RTSMediaSegmentsController *)controller
	 segmentsForIdentifier:(NSString *)identifier
	 withCompletionHandler:(RTSMediaSegmentsCompletionHandler)completionHandler;

@end
