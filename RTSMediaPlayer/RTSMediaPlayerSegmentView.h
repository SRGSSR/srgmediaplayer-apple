//
//  Created by Samuel Défago on 22.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegment.h>
#import <RTSMediaPlayer/RTSMediaPlayerSegmentDataSource.h>

#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;

@protocol RTSMediaPlayerSegmentView <NSObject>

- (void) reloadWithSegments:(NSArray *)segments;

@property (nonatomic) NSTimeInterval reloadInterval;

@end

/**
 *  An abstract base view class for views displaying segment information. Ensures:
 *    - Initial retrieval of segments
 *    - Periodic retrieval of segments
 */
@interface RTSMediaPlayerSegmentView : UIView <RTSMediaPlayerSegmentView>

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet id<RTSMediaPlayerSegmentDataSource> dataSource;

@end
