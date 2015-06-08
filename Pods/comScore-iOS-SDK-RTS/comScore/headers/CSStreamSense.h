//
//  CSStreamSensePuppet.h
//  ComScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

#import "CSStreamSenseState.h"

@class CSStreamSensePlaylist;
@class CSStreamSenseClip;
@class CSCore;

typedef enum {
    CSStreamSensePlay,
    CSStreamSenseBuffer,
    CSStreamSensePause,
    CSStreamSenseEnd,
    CSStreamSenseKeepAlive,
    CSStreamSenseHeartbeat,
    CSStreamSenseAdPlay,
    CSStreamSenseAdPause,
    CSStreamSenseAdEnd,
    CSStreamSenseAdClick,
    CSStreamSenseCustom
} CSStreamSenseEventType;

extern NSString *const CSStreamSenseEventType_toString[12];

@interface CSStreamSense : NSObject {
@protected
    NSMutableDictionary *_persistentLabels;
    NSString *_pixelURL;
    CSCore *_core;
    CSStreamSensePlaylist *_playlist;
    CSStreamSenseState _currentState;
    CSStreamSenseState _prevState;
    CSStreamSenseState _lastStateWithMeasurement;
    NSString *_keepAliveTimerId;
    NSString *_heartbeatTimerId;
    NSString *_pausedOnBufferingTimerId;
    NSString *_delayedTransitionTimerId;
    int _heartbeatCount;
    NSTimeInterval _nextHeartbeatInterval, _nextHeartbeatTimestamp;
    NSTimeInterval _previousStateTime;
    NSTimeInterval _keepAliveInterval;
    NSTimeInterval _pauseOnBufferingInterval;
    NSMutableArray *_delegates;

    NSString *_mediaPlayerName, *_mediaPlayerVersion;
    NSMutableDictionary *_measurementSnapshot;

    NSMutableArray *_heartbeatIntervals;

    long _lastKnownPosition;
    int _nextEventCount;
}

- (id)init;

@property(assign) BOOL sendPauseOnRebuffering;
@property(assign) BOOL pausePlaySwitchDelayEnabled;

- (NSMutableDictionary *)createMeasurementLabelsWithInitialLabels:(NSDictionary *)initialLabels;

- (NSMutableDictionary *)createMeasurementLabels:(CSStreamSenseEventType)eventType initialLabels:(NSDictionary *)initialLabels;

- (void)setLabel:(NSString *)name value:(NSString *)value;

- (void)setLabels:(NSDictionary *)dictionary;

- (NSString *)label:(NSString *)name;

- (NSMutableDictionary *)labels;

- (void)reset;

- (void)reset:(NSArray *)keepLabels;

- (BOOL)notify:(CSStreamSenseEventType)playerEvent position:(long)ms;

- (BOOL)notify:(CSStreamSenseEventType)playerEvent position:(long)ms labels:(NSDictionary *)labels;

- (CSStreamSenseClip *)clip;

- (BOOL)setClip:(NSDictionary *)labels;

- (BOOL)setClip:(NSDictionary *)labels playlistLoop:(BOOL)loop;

- (CSStreamSensePlaylist *)playlist;

- (BOOL)setPlaylist:(NSDictionary *)labels;

- (CSStreamSenseState)state;

- (void)importState:(NSDictionary *)labels;

- (NSDictionary *)exportState;

- (NSString *)version;

- (NSString *)setPixelURL:(NSString *)value;

- (void)setHeartbeatIntervals:(NSArray *)intervals;

- (void)setPauseOnBufferingInterval:(NSTimeInterval)interval;

- (NSTimeInterval)pauseOnBufferingInterval;

- (void)setKeepAliveInterval:(NSTimeInterval)interval;

- (NSTimeInterval)keepAliveInterval;

@end
