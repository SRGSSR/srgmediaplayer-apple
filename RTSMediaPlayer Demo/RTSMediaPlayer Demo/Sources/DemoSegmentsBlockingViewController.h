//
//  DemoSegmentsBlockingViewController.h
//  RTSMediaPlayer Demo
//
//  Created by Cédric Foellmi on 01/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayer.h>
#import <UIKit/UIKit.h>

@interface DemoSegmentsBlockingViewController : UIViewController <RTSTimelineSliderDelegate, RTSTimelineViewDelegate>

@property (nonatomic, copy) NSString *videoIdentifier;

@end
