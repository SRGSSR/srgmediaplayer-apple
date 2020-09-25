//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

@import AVFoundation;

#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGMediaPlayerView;

/**
 *  Media player view delegate protocol.
 */
@protocol SRGMediaPlayerViewDelegate <NSObject>

/**
 *  Called when the view has been added to a window (`nil` if removed from its parent window).
 */
- (void)mediaPlayerView:(SRGMediaPlayerView *)mediaPlayerView didMoveToWindow:(nullable UIWindow *)window;

@end

/**
 *  Private interface for internal use.
 */
@interface SRGMediaPlayerView (Private)

#if TARGET_OS_IOS

/**
 *  The motion manager which has been set, if any.
 */
@property (class, nonatomic, readonly, nullable) CMMotionManager *motionManager;

#endif

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

/**
 *  The view delegate.
 */
@property (nonatomic, weak) id<SRGMediaPlayerViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
