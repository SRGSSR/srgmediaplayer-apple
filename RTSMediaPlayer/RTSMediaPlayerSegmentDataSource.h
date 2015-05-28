//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RTSMediaPlayer/RTSMediaPlayerSegment.h>
#import <RTSMediaPlayer/RTSMediaPlayerSegmentController.h>

@protocol RTSMediaPlayerSegmentDataSource <NSObject>

@required
- (void)playerOverlayView:(UIView *)view
    segmentsForIdentifier:(NSString *)identifier
        completionHandler:(void (^)(NSArray *segments, NSError *error))completionHandler;

- (

@end
