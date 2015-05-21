//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegmentOverlayDataSource.h>

#import <UIKit/UIKit.h>

@interface RTSMediaPlayerSegmentOverlay : UIView

@property (nonatomic, weak) IBOutlet id<RTSMediaPlayerSegmentOverlayDataSource> dataSource;

@end
