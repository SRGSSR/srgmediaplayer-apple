//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerController.h>
#import <RTSMediaPlayer/RTSMediaPlayerSegmentOverlayDataSource.h>

#import <UIKit/UIKit.h>

@interface RTSMediaPlayerSegmentOverlayView : UIView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet id<RTSMediaPlayerSegmentOverlayDataSource> dataSource;

@end
