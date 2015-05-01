//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSTimelineEvent.h>
#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;
@class RTSTimelineView;

@interface RTSTimelineView : UIView <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSArray *events;

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@end
