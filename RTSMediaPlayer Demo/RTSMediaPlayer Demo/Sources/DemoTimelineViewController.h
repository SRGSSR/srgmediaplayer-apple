//
//  Created by Samuel Défago on 29.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayer.h>
#import <UIKit/UIKit.h>

@interface DemoTimelineViewController : UIViewController <RTSMediaPlayerControllerDataSource, RTSTimelineViewDataSource, RTSTimelineViewDelegate>

@property (nonatomic, copy) NSString *videoIdentifier;

@end
