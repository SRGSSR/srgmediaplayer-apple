//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPosition.h"

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SRGPlayer;

@protocol SRGPlayerDelegate <NSObject>

// Called on the main thread
- (void)player:(SRGPlayer *)player willSeekToPosition:(SRGPosition *)position;
- (void)player:(SRGPlayer *)player didSeekToPosition:(SRGPosition *)position finished:(BOOL)finished;

@end

@interface SRGPlayer : AVPlayer

@property (nonatomic, weak) id<SRGPlayerDelegate> delegate;

@property (nonatomic, readonly, getter=isSeeking) BOOL seeking;

/**
 *  Attempt to play the media immediately if possible (iOS 10 and greater), otherwise normally.
 */
- (void)playImmediatelyIfPossible;

- (void)seekToPosition:(nullable SRGPosition *)position notify:(BOOL)notify completionHandler:(void (^)(BOOL finished))completionHandler;

@end

NS_ASSUME_NONNULL_END
