//
//  CScomScore.h
//  comScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

#ifndef CSCOMSCORE_H
#define CSCOMSCORE_H

#import "CSEventType.h"
#import "CSTransmissionMode.h"
#import "CSApplicationState.h"
#import "CSSessionState.h"
#import "CSComScore.h"

@class CSCacheFlusher;
@class CSCensus;
@class CSNotificationsObserver;
@class CSOfflineCache;
@class CSStorage;
@class CSKeepAlive;
@class CSTaskExecutor;
@class CSMeasurementDispatcher;

/**
 ComScore analytics interface
 */
@interface CSCore : NSObject{
    NSString *_visitorID;
    NSString *_publisherSecret;
    NSString *_appName;
    NSString *_devModel;
    NSMutableDictionary *_labels;
    NSMutableDictionary *_autoStartLabels;
    BOOL _keepAliveEnabled;
    long cacheFlushingInterval;
    NSString *_crossPublisherId;
    NSString *_md5CrossPublisherRawId;
    BOOL _isCrossPublisherIdBasedOnIFDA;
    BOOL _errorHandlingEnabled;
    NSUncaughtExceptionHandler *_defaultUncaughtExceptionHandler;
    BOOL _autoStartEnabled;
    BOOL _secure;
    CSTransmissionMode _liveTransmissionMode;
    CSTransmissionMode _offlineTransmissionMode;
    NSArray *_measurementLabelOrder;
    NSNumber *_adSupportFrameworkAvailable; // this is used so that we only check once for availability of the ad support framework
    
    BOOL _adIdChanged;
    int _adIdEnabled; // -1: not setted, 0 disabled, 1 enabled
    BOOL _idChangedWhenAppNotRunning;
    
    CSStorage *_storage;
    CSTaskExecutor *_taskExecutor;
    CSMeasurementDispatcher *_measurementDispatcher;
    CSOfflineCache *_offlineCache;
    CSNotificationsObserver *observer;
    CSKeepAlive *_keepAlive;
    CSCacheFlusher *_cacheFlusher;
    NSMutableSet *_ssids;
    
    // Common state machine fields
    long long _autoUpdateInterval;
    BOOL _autoUpdateInForegroundOnly;
    int _runsCount;
    long long _coldStartId;
    int _coldStartCount;
    BOOL _coldStart;
    long long _installId;
    long long _firstInstallId;
    NSString *_currentVersion;
    NSString *_previousVersion;
    
    // Application State Machine
    CSApplicationState _currentApplicationState;
    int _foregroundComponentsCount;
    int _activeUxComponentsCount;
    int _foregroundTransitionsCount;
    long long _totalForegroundTime;
    long long _accumulatedBackgroundTime;
    long long _accumulatedForegroundTime;
    long long _accumulatedInactiveTime;
    long long _genesis;
    long long _previousGenesis;
    long long _lastApplicationAccumulationTimestamp;
    long long _totalBackgroundTime;
    long long _totalInactiveTime;
    
    // Session State Machine
    CSSessionState _currentSessionState;
    long long _accumulatedApplicationSessionTime;
    long long _accumulatedUserSessionTime;
    long long _accumulatedActiveUserSessionTime;
    int _userSessionCount;
    int _activeUserSessionCount;
    long long _lastApplicationSessionTimestamp;
    long long _lastUserSessionTimestamp;
    long long _lastActiveUserSessionTimestamp;
    int _userInteractionCount;
    long long _lastUserInteractionTimestamp;
    long long _lastSessionAccumulationTimestamp;
    int _applicationSessionCount;
    NSString *_userInteractionTimerId;
    NSString *_autoUpdateTimerId;
    
    BOOL _enabled;
    BOOL _wasErrorHandlingEnabled;
}

/**
 PixelURL setter.
 
 Parameters:
 
 - value: A NSString that contains the PixelURL.
 */
- (NSString *)setPixelURL:(NSString *)value;

/**
 Notify Application event (Start / Close / Aggregate) with custom labels
 
 Parameters:
 
 - type: A CSApplicationEventType enum that value must be Start, Close or Aggregate.
 - labels: A NSDictionary that contains a set of custom labels with key-value pairs.
 */
- (void)notifyWithApplicationEventType:(CSApplicationEventType)type labels:(NSDictionary *)labels;

- (id)init;

- (CSStorage *)storage;

- (CSOfflineCache *)offlineCache;

- (CSNotificationsObserver *)observer;

- (CSKeepAlive *)keepAlive;

- (CSCacheFlusher *)cacheFlusher;

- (void)setVisitorId:(NSString *)value;

- (void)resetVisitorID;

- (void)restoreVisitorId;

- (NSString *)visitorId;

- (void)setPublisherSecret:(NSString *)value;

- (NSString *)publisherSecret;

- (void)appName:(NSString *)value;

- (NSString *)appName;

- (NSString *)devModel;

- (NSString *)generateVisitorId;

- (NSString *)generateVisitorIdWithPublisherSecret:(NSString *)publisherSecret;

- (long long)genesis;

- (long long)previousGenesis;

- (NSString *)getPlainMACAddress;

- (void)setLabel:(NSString *)name value:(NSString *)value;

- (void)setLabels:(NSDictionary *)labels;

- (NSMutableDictionary *)labels;

- (NSString *)label:(NSString *)labelName;

- (void)setAutoStartLabel:(NSString *)name value:(NSString *)value;

- (void)setAutoStartLabels:(NSDictionary *)labels;

- (NSMutableDictionary *)autoStartLabels;

- (NSString *)autoStartLabel:(NSString *)labelName;

- (BOOL)isKeepAliveEnabled;

- (void)setKeepAliveEnabled:(BOOL)enabled;

- (void)setCustomerC2:(NSString *)c2;

- (NSString *)customerC2;

- (void)setSecure:(BOOL)secure;

- (BOOL)isSecure;

- (NSString *)crossPublisherId;

- (BOOL)crossPublisherIdChanged;

- (NSArray *)measurementLabelOrder;

- (void)disableAutoUpdate;

- (void)enableAutoUpdate:(int)intervalInSeconds foregroundOnly:(BOOL)foregroundOnly;

- (int)coldStartCount;

- (long long)coldStartId;

- (NSString *)currentVersion;

- (long long)firstInstallId;

- (long long)installId;

- (NSString *)previousVersion;

- (int)runsCount;

- (BOOL)handleColdStart:(long long)timestamp;

- (BOOL)isAutoUpdateEnabled;

- (void)onEnterForeground;

- (void)onExitForeground;

- (void)onUserInteraction;

- (void)onUxActive;

- (void)onUxInactive;

- (void)setMeasurementLabelOrder:(NSArray *)ordering;

- (void)update:(long long)timestamp store:(BOOL)store;

- (NSString *)version;

- (BOOL)isJailBroken;

- (long long)totalBackgroundTime:(BOOL)reset;

- (long long)totalInactiveTime:(BOOL)reset;

- (BOOL)coldStart;

- (void)update;

- (BOOL)isNotProperlyInitialized;

- (void)setOfflineURL:(NSString *)value;

- (void)setOfflineURL:(NSString *)value background:(BOOL)background;


/** 
 Enables or disables live events (GETs) dispatched one by one when connectivity is available
 */
- (void)allowLiveTransmission:(CSTransmissionMode)mode;

/**
 Enables or disables automatic offline cache flushes (POSTS). The cache can always be manually 
 flushed using the public api comScore.FlushOfflineCache()
 */
- (void)allowOfflineTransmission:(CSTransmissionMode)mode;


/**
 Returns the live transmission mode
 */
- (CSTransmissionMode)liveTransmissionMode;

/**
 Returns the offline transmission mode
 */
- (CSTransmissionMode)offlineTransmissionMode;

- (long)cacheFlushingInterval;

- (void)setCacheFlushingInterval:(long)seconds;

/** Returns the task executor queue.
    The task executor queue is used to perform sequential operations in a background thread.
 */
- (CSTaskExecutor *)taskExecutor;

/** Returns the measurement dispatcher instance */
- (CSMeasurementDispatcher *)measurementDispatcher;

- (BOOL)autoStartEnabled;

- (void)setAutoStartEnabled:(BOOL)value;

/**
 * Enables or disables tracking. When tracking is disabled, no measurement is sent and
 * no data is collected.
 */
- (void)setEnabled:(BOOL)enabled;

/**
 * Indicates if tracking is enabled. When tracking is disabled, no measurement is sent and
 * no data is collected.
 */
- (BOOL)enabled;


@property(nonatomic, assign, getter = isErrorHandlingEnabled) BOOL errorHandlingEnabled;
@property(readonly, nonatomic, assign) NSString *pixelURL;

@end

#endif // ifndef CSCOMSCORE_H