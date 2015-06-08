//
//  StreamSenseDelegate.h
//  comScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

#import "CSStreamSenseDefines.h"

@protocol CSStreamSenseDelegate

- (void)onStateChange:(CSStreamSenseState)oldState
             newState:(CSStreamSenseState)newState
          eventLabels:(NSDictionary *)eventLabels
            timeDelta:(NSTimeInterval)timeDelta;

@end