//
//  CSStreamSenseState.h
//  comScore
//
//  Copyright (c) 2014 comScore. All rights reserved.
//

#ifndef comScore_CSStreamSenseState_h
#define comScore_CSStreamSenseState_h

typedef enum {
    CSStreamSenseStateIdle,
    CSStreamSenseStatePlaying,
    CSStreamSenseStatePaused,
    CSStreamSenseStateBuffering
} CSStreamSenseState;

extern NSString *const CSStreamSenseState_toString[4];

#endif
