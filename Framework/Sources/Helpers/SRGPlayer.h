//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGPlayer : AVPlayer

/**
 *  Attempt to play the media immediately if possible (iOS 10 and greater), otherwise normally.
 */
- (void)playImmediatelyIfPossible;

/**
 *  Same as `-seekToTime:toleranceBefore:toleranceAfter:completionHandler:`, but counting the number of seek requests still
 *  pending.
 */
- (void)countedSeekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL finished, NSInteger pendingSeekCount))completionHandler;

@end

NS_ASSUME_NONNULL_END
