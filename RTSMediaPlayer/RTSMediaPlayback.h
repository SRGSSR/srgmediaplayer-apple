//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol RTSMediaPlayback <NSObject>

// *** Controling Playback ***

/**
 *  Prepare to play
 */
- (void)prepareToPlay;

/**
 *  Play
 */
- (void)play;

/**
 *  Start playing media specified with its identifier.
 *
 *  @param identifier the identifier of the media to be played.
 *
 *  @discussion the dataSource will be used to determine the URL of the media.
 */
- (void)playIdentifier:(NSString *)identifier;

/**
 *  Pause
 */
- (void)pause;

/**
 *  Reset
 */
- (void)reset;

/**
 *  Mute the volume of the playback;
 *
 *  @param flag A boolean value
 */
- (void)mute:(BOOL)flag;

/**
 *  Seek to specific time of the playback.
 *
 *  @param time              time in seconds
 *  @param completionHandler the completion handler.
 */
- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;


// *** Accessing Playback Information ***

- (AVPlayerItem *)playerItem;


@end
