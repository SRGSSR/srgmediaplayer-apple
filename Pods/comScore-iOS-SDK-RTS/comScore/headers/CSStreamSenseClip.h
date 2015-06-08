//
//  CSStreamSenseClip.h
//  ComScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

#import <Foundation/Foundation.h>
#import "CSStreamSenseDefines.h"
#import "CSStreamSense.h"

@interface CSStreamSenseClip : NSObject {
    NSMutableDictionary *_labels;
    NSTimeInterval _playbackTime;
    NSTimeInterval _bufferingTime;
    NSTimeInterval _playbackTimestamp;
    NSTimeInterval _bufferingTimestamp;
    NSInteger _pauses;
    NSInteger _starts;
    NSString *_clipId;
}

- (void)setRegisters:(NSMutableDictionary *)labels forState:(CSStreamSenseState)state;

- (void)reset;

- (void)reset:(NSArray *)keepLabels;

- (NSMutableDictionary *)createLabels:(CSStreamSenseEventType)eventType initialLabels:(NSDictionary *)initialLabels;

- (void)setLabels:(NSDictionary *)dictionary;

- (void)setLabel:(NSString *)name value:(NSString *)value;

- (void)setLabels:(NSDictionary *)newLabels forState:(CSStreamSenseState)state;

- (NSString *)label:(NSString *)name;

- (NSMutableDictionary *)labels;

@end
