//
//  CSStreamSensePlugin.h
//  comScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

#import "CSStreamSenseDefines.h"
#import "CSStreamSense.h"

@interface CSStreamSensePlugin : CSStreamSense

- (id)initWithPluginName:(NSString *)pluginName andPluginVersion:(NSString *)pluginVersion andPlayerVersion:(NSString *)playerVersion;

- (BOOL)notify:(CSStreamSenseEventType)playerEvent position:(long)ms labels:(NSDictionary *)labels;

- (BOOL)setClip:(NSDictionary *)labels;

- (BOOL)setClip:(NSDictionary *)labels playlistLoop:(BOOL)loop;

- (void)addLabelHandler:(void (^)(CSStreamSenseEventType, NSDictionary *))handler;

- (void)clearAllLabelHandlers;

- (void)setBitRate:(long)value;

- (void)setVideoSize:(NSString *)value;

- (void)setDuration:(long)value;

- (void)setVolume:(NSUInteger)value;

- (void)setIsFullScreen:(BOOL)value;

#pragma mark Smart State Detection

- (void)setDetectSeek:(BOOL)value;

- (void)setDetectPause:(BOOL)value;

- (void)setDetectPlay:(BOOL)value;

- (void)setDetectEnd:(BOOL)value;

- (void)setSmartStateDetection:(BOOL)value;

- (void)setPauseDetectionErrorMargin:(NSUInteger)value;

- (void)setEndDetectionErrorMargin:(NSUInteger)value;

- (void)setSeekDetectionMinQuotient:(float)value;

- (void)setPulseSamplingInterval:(NSUInteger)value;

- (void)setMaximumNumberOfEntriesInHistory:(NSUInteger)value;

- (void)setMinimumNumberOfTimeUpdateEventsBeforeSensingAnything:(NSUInteger)value;

@end
