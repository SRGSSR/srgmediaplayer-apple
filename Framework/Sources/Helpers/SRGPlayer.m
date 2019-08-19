//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPlayer.h"

@interface SRGPlayer ()

@property (nonatomic) NSInteger seekCount;

@end

@implementation SRGPlayer

#pragma mark Getters and setters

- (BOOL)isSeeking
{
    return self.seekCount != 0;
}

#pragma mark Playback

// TODO: Remove when iOS / tvOS 10 is the minimum required version.
- (void)playImmediatelyIfPossible
{
    if (@available(iOS 10, tvOS 10, *)) {
        [self playImmediatelyAtRate:1.f];
    }
    else {
        [self play];
    }
}

// Might be called from a background thread, in which case the completion handler might as well
- (void)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL finished))completionHandler
{
    SRGPosition *position = [SRGPosition positionWithTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter];
    [self seekToPosition:position notify:YES completionHandler:completionHandler];
}

- (void)seekToPosition:(SRGPosition *)position notify:(BOOL)notify completionHandler:(void (^)(BOOL))completionHandler
{
    if (! position) {
        position = SRGPosition.defaultPosition;
    }
    
    if (notify) {
        if (NSThread.isMainThread) {
            [self.delegate player:self willSeekToPosition:position];
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate player:self willSeekToPosition:position];
            });
        }
    }
    
    ++self.seekCount;
    
    [super seekToTime:position.time toleranceBefore:position.toleranceBefore toleranceAfter:position.toleranceAfter completionHandler:^(BOOL finished) {
        --self.seekCount;
        
        if (notify && finished) {
            if (NSThread.isMainThread) {
                [self.delegate player:self didSeekToPosition:position];
            }
            else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate player:self didSeekToPosition:position];
                });
            }
        }
        
        completionHandler(finished);
    }];
}

@end
