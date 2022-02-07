//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

@class SRGPlayer;

/**
 *  Player delegate protocol.
 */
@protocol SRGPlayerDelegate <NSObject>

/**
 *  The player begins seeking to the given time.
 */
- (void)player:(SRGPlayer *)player willSeekToTime:(CMTime)time;

/**
 *  The player did finish seeking to the given time.
 *
 *  @discussion Not called if a seek has been interrupted.
 */
- (void)player:(SRGPlayer *)player didSeekToTime:(CMTime)time;

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
- (void)playImmediatelyIfPossibleAtRate:(float)rate;

/**
 *  Seek to a given time with the provided tolerances, calling the specified handler on completion. The delegate
 *  methods are called iff `notify` is set to `YES`.
 *
 *  @discussion The parent `-seekToTime:toleranceBefore:toleranceAfter:completionHandler:` method always notifies
 *              the player delegate. Refer to this method documentation for more information about the parameters
 *              and their role.
 */
- (void)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter notify:(BOOL)notify completionHandler:(void (^)(BOOL finished))completionHandler;

@end

NS_ASSUME_NONNULL_END
