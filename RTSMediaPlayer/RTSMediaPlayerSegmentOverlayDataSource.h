//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegment.h>
#import <Foundation/Foundation.h>

@class RTSMediaPlayerSegmentOverlay;

@protocol RTSMediaPlayerSegmentOverlayDataSource <NSObject>

@required
- (void) mediaPlayerSegmentOverlay:(RTSMediaPlayerSegmentOverlay *)mediaPlayerSegmentOverlay segmentsForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSArray *segments, NSError *error))completionHandler;

@end
