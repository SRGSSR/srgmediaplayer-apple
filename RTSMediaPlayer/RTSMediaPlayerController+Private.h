//
//  RTSMediaPlayerController+Private.h
//  RTSMediaPlayer
//
//  Created by Cédric Foellmi on 01/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerController.h"
#import <TransitionKit/TransitionKit.h>

@interface RTSMediaPlayerController (Private)

- (void)fireSeekEventWithUserInfo:(NSDictionary *)userInfo;

@end
