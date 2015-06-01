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

@property (readwrite) TKState *idleState;
@property (readwrite) TKState *readyState;
@property (readwrite) TKState *pausedState;
@property (readwrite) TKState *playingState;
@property (readwrite) TKState *seekingState;
@property (readwrite) TKState *stalledState;

@property (readwrite) TKEvent *loadEvent;
@property (readwrite) TKEvent *loadSuccessEvent;
@property (readwrite) TKEvent *playEvent;
@property (readwrite) TKEvent *pauseEvent;
@property (readwrite) TKEvent *seekEvent;
@property (readwrite) TKEvent *endEvent;
@property (readwrite) TKEvent *stopEvent;
@property (readwrite) TKEvent *stallEvent;
@property (readwrite) TKEvent *resetEvent;

- (TKStateMachine *)stateMachine;
- (void)fireEvent:(TKEvent *)event userInfo:(NSDictionary *)userInfo;

@end
