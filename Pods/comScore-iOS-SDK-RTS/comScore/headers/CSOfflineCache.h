//
//  CSOfflineMeasurementFileCache.h
//  comScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

@class CSMeasurement;
@class CSCore;

@interface CSOfflineCache : NSObject {

    NSURLConnection *_connection;
    NSMutableArray *_arrayOfCacheFiles;
    NSURLRequest *_request;
    NSString *_url;

    int _flushesInARow;
    NSTimeInterval _lastFlushDate;
    NSTimeInterval _lastFailDate;

    // Common labels to be aggrupped in the header of the xml
    NSString *_c12;
    NSString *_c1;
    NSString *_ns_ap_an;
    NSString *_ns_ap_pn;
    NSString *_ns_ap_device;
    NSString *_ns_ak;
    NSMutableString *_concatedProcessedEvents;

    CSCore *core;
}

- (id)initWithCore:(CSCore *)aCore;

- (int)count;

- (BOOL)isEmpty;

- (NSArray *)newestEventBatch;

- (BOOL)removeAllEvents;

- (BOOL)flush;

- (BOOL)isAutomaticFlushAllowed;

- (BOOL)automaticFlush;

- (void)saveMeasurement:(CSMeasurement *)m;

@property(nonatomic, retain) NSString *url;
@property(nonatomic, assign) int maxSize;
@property(nonatomic, assign) int maxBatchSize;
@property(nonatomic, assign) int maxFlushesInARow;
@property(nonatomic, assign) int minutesToRetry;
@property(nonatomic, assign) int expiryInDays;

@end
