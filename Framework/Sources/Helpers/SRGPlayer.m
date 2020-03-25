//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPlayer.h"

@interface SRGPlayer ()

@property (nonatomic) NSInteger seekCount;

@property (nonatomic) CMTime seekStartTime;
@property (nonatomic) CMTime seekTargetTime;

@end

@implementation SRGPlayer

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.seekStartTime = kCMTimeIndefinite;
        self.seekTargetTime = kCMTimeIndefinite;
    }
    return self;
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
    [self seekToTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter completionHandler:completionHandler];
}

- (void)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter notify:(BOOL)notify completionHandler:(void (^)(BOOL))completionHandler
{
    if (self.seekCount == 0) {
        self.seekStartTime = self.currentTime;
    }
    self.seekTargetTime = time;
    
    if (notify) {
        if (NSThread.isMainThread) {
            [self.delegate player:self willSeekToTime:time];
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate player:self willSeekToTime:time];
            });
        }
    }
    
    ++self.seekCount;
    
    [super seekToTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter completionHandler:^(BOOL finished) {
        --self.seekCount;
        
        if (finished) {
            if (notify) {
                if (NSThread.isMainThread) {
                    [self.delegate player:self didSeekToTime:time];
                }
                else {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.delegate player:self didSeekToTime:time];
                    });
                }
            }
            
            self.seekStartTime = kCMTimeIndefinite;
            self.seekTargetTime = kCMTimeIndefinite;
        }
        
        completionHandler(finished);
    }];
}

@end
