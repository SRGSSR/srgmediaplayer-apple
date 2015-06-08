//
//  CSKeepAlive.h
//  comScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

@class CSCore;

@interface CSKeepAlive : NSObject {
    NSString *_timerId;
    CSCore *_core;
    long long _timeout;
    long long _nextKeepAliveTime;
    long long _currentTimeout;
    BOOL _foreground;
}

- (id)initWithCore:(CSCore *)aCore timeout:(long long)timeout;

- (void)sendKeepAlive;

- (void)reset;

- (void)reset:(long long)timeout;

- (void)processKeepAlive:(BOOL)saveInCache;

- (void)start:(long long)millis;

- (void)stop;


@end
