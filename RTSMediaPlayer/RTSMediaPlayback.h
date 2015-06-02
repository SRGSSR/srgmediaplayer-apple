//
//  RTSMediaPlayback.h
//  RTSMediaPlayer
//
//  Created by Cédric Foellmi on 02/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RTSMediaPlayback <NSObject>

/**
 *  Prepare to play
 */
- (void)prepareToPlay;

/**
 *  Play
 */
- (void)play;

/**
 *  Pause
 */
- (void)pause;

/**
 *  Reset
 */
- (void)reset;

/**
 *  Seek to specific time of the playback.
 *
 *  @param time              time in seconds
 *  @param completionHandler the completion handler.
 */
- (void)seekToTime:(NSTimeInterval)seconds completionHandler:(void (^)(BOOL finished))completionHandler;


@end
