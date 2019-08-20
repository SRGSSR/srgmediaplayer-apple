//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPosition.h"

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SRGPlayer;

/**
 *  Player delegate protocol.
 */
@protocol SRGPlayerDelegate <NSObject>

/**
 *  The player begins seeking to the given position.
 */
- (void)player:(SRGPlayer *)player willSeekToPosition:(SRGPosition *)position;

/**
 *  The player did finish seeking to the given position.
 *
 *  @discussion Not called if a seek has been interrupted.
 */
- (void)player:(SRGPlayer *)player didSeekToPosition:(SRGPosition *)position;

@end

/**
 *  Lightweight `AVPlayer` subclass tracking seek events and reporting them to its delegate.
 */
@interface SRGPlayer : AVPlayer

/**
 *  The player delegate.
 */
@property (nonatomic, weak) id<SRGPlayerDelegate> delegate;

/**
 *  Returns `YES` iff the player is currently seeking to some location.
 */
@property (nonatomic, readonly, getter=isSeeking) BOOL seeking;

/**
 *  The time at which the player started seeking, `kCMTimeIndefinite` if no seek is currently being made.
 */
@property (nonatomic, readonly) CMTime seekStartTime;

/**
 *  The current time to which the player is seeking, `kCMTimeIndefinite` if no seek is currently being made.
 */
@property (nonatomic, readonly) CMTime seekTargetTime;

/**
 *  Attempt to play the media immediately if possible (iOS 10 and greater), otherwise normally.
 */
- (void)playImmediatelyIfPossible;

/**
 *  Seek to a position (default position if `nil`), calling the specified handler on completion. The delegate methods
 *  are called iff `notify` is set to `YES`.
 *
 *  @discussion The parent `-seekToTime:toleranceBefore:toleranceAfter:completionHandler:` method always notifies
 *              the player delegate.
 */
- (void)seekToPosition:(nullable SRGPosition *)position notify:(BOOL)notify completionHandler:(void (^)(BOOL finished))completionHandler;

@end

NS_ASSUME_NONNULL_END
