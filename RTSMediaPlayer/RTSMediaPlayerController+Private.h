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

/**
 *  -------------------
 *  @name Player Object
 *  -------------------
 */
/**
 *  The player that provides the media content.
 *
 *  @discussion This can be used for exemple to listen to `addPeriodicTimeObserverForInterval:queue:usingBlock:` or to
 *  implement advanced behaviors
 */
@property(readonly) AVPlayer *player;

- (void)fireSeekEventWithUserInfo:(NSDictionary *)userInfo;

@end
