//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegment.h>
#import <Foundation/Foundation.h>

@protocol RTSMediaPlayerSegmentDisplayer <NSObject>

- (void) reloadWithSegments:(NSArray *)segments;

@end

@protocol RTSMediaPlayerSegmentDataSource <NSObject>

@required
- (void) segmentDisplayer:(id<RTSMediaPlayerSegmentDisplayer>)segmentDisplayer segmentsForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSArray *segments, NSError *error))completionHandler;

@end
