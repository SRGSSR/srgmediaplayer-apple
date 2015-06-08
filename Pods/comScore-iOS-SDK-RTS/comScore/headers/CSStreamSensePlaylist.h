//
//  CSStreamSensePlaylist.h
//  ComScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

#import <Foundation/Foundation.h>
#import "CSStreamSenseDefines.h"
#import "CSStreamSenseClip.h"

@interface CSStreamSensePlaylist : NSObject {
    NSMutableDictionary *_labels;
    CSStreamSenseClip *_clip;
    NSTimeInterval _bufferingTime;
    NSTimeInterval _playbackTime;
    NSString *_playlistId;
    NSInteger _pauses;
    NSInteger _starts;
    NSInteger _rebufferCount;
    NSInteger _playlistCounter;
    NSInteger _firstPlayOccurred;
}

- (void)reset;

- (void)reset:(NSArray *)keepLabels;

- (void)setRegisters:(NSMutableDictionary *)labels forState:(CSStreamSenseState)state;

- (void)setLabels:(NSDictionary *)newLabels forState:(CSStreamSenseState)state;

- (NSMutableDictionary *)createLabels:(CSStreamSenseEventType)eventType initialLabels:(NSDictionary *)initialLabels;

- (void)addPlaybackTime:(NSTimeInterval)now;

- (void)addBufferingTime:(NSTimeInterval)now;

- (void)setLabel:(NSString *)name value:(NSString *)value;

- (void)setLabels:(NSDictionary *)dictionary;

- (NSString *)label:(NSString *)name;

- (NSMutableDictionary *)labels;

@end