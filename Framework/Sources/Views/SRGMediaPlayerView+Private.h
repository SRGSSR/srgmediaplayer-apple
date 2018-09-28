//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Private interface for internal use.
 */
@interface SRGMediaPlayerView (Private)

/**
 *  The motion manager which has been set, if any.
 */
@property (class, nonatomic, readonly, nullable) CMMotionManager *motionManager;

/**
 *  The player associated with the view.
 */
@property (nonatomic, nullable) AVPlayer *player;

/**
 *  The player layer associated with the view.
 */
@property (nonatomic, readonly, nullable) AVPlayerLayer *playerLayer;

/**
 *  Set to `YES` to hide the internal view used for playback. Default is `NO`.
 */
@property (nonatomic, getter=isPlaybackViewHidden) BOOL playbackViewHidden;

@end

NS_ASSUME_NONNULL_END
