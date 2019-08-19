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

- (BOOL)isSeeking
{
    return self.seekCount != 0;
}

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
        [self.delegate player:self willSeekToPosition:position];
    }
    
    ++self.seekCount;
    
    [super seekToTime:position.time toleranceBefore:position.toleranceBefore toleranceAfter:position.toleranceAfter completionHandler:^(BOOL finished) {
        --self.seekCount;
        
        if (notify) {
            [self.delegate player:self didSeekToPosition:position finished:finished];
        }
        
        completionHandler(finished);
    }];
}

@end
