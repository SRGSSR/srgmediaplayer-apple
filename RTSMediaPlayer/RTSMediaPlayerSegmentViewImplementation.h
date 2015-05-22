//
//  Created by Samuel Défago on 22.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegmentDataSource.h>
#import <Foundation/Foundation.h>

@class RTSMediaPlayerController;
@protocol RTSMediaPlayerSegmentView;

@interface RTSMediaPlayerSegmentViewImplementation : NSObject

- (instancetype) initWithView:(id<RTSMediaPlayerSegmentView>)view;

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;
@property (nonatomic, weak) IBOutlet id<RTSMediaPlayerSegmentDataSource> dataSource;

- (void) reloadSegments;

@end

@interface RTSMediaPlayerSegmentViewImplementation (UnavailableMethods)

- (instancetype) init NS_UNAVAILABLE;

@end
