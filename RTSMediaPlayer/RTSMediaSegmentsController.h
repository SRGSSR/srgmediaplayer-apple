//
//  RTSMediaSegmentsController.h
//  RTSMediaPlayer
//
//  Created by Cédric Foellmi on 27/05/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTSMediaPlayerSegmentDataSource.h"

@interface RTSMediaSegmentsController : NSObject

@property(nonatomic, weak) id<RTSMediaPlayerSegmentDataSource> dataSource;

@end
