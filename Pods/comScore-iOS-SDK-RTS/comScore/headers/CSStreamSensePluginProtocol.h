//
//  CSStreamSensePluginProtocol.h
//  comScore
//
//  Copyright (c) 2014 comScore. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CSStreamSensePluginProtocol <NSObject>
- (long)currentPositionInMilliseconds;

@optional
- (BOOL) willSendMeasurement:(CSStreamSenseState) state EventType:(CSStreamSenseEventType) eventType SeekFlag:(BOOL) seekFlag;
- (void) didSendMeasurement:(CSStreamSenseState) state;
@end
