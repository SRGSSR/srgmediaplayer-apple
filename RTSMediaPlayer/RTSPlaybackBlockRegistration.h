//
//  Created by Samuel Défago on 30.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@interface RTSPlaybackBlockRegistration : NSObject

- (instancetype)initWithPlaybackBlock:(void (^)(CMTime time))playbackBlock interval:(CMTime)interval NS_DESIGNATED_INITIALIZER OS_NONNULL_ALL;

@property (nonatomic, readonly, copy) void (^playbackBlock)(CMTime time);
@property (nonatomic, readonly) CMTime interval;

@property (nonatomic, readonly, weak) AVPlayer *player;
@property (nonatomic, readonly) id periodicTimeObserver;

- (void)registerWithMediaPlayer:(AVPlayer *)player;
- (void)unregister;

@end
