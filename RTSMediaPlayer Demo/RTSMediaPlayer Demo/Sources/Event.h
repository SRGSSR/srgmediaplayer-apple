//
//  Created by Samuel Défago on 01.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSTimelineEvent.h>

@interface Event : RTSTimelineEvent

- (instancetype)initWithTime:(CMTime)time title:(NSString *)title identifier:(NSString *)identifier;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *identifier;

@end
