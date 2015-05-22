//
//  Created by Samuel Défago on 01.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegment.h>
#import <UIKit/UIKit.h>

@interface Event : RTSMediaPlayerSegment

- (instancetype) initWithTime:(CMTime)time title:(NSString *)title identifier:(NSString *)identifier date:(NSDate *)date;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly) NSDate *date;

@property (nonatomic, readonly) NSURL *imageURL;

@end
