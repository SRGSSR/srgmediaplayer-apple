//
//  CSCensus.h
//  ComScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

@interface CSCensus : NSObject {

    NSString *_customerID;
}

- (id)init;

- (void)notifyStart:(NSString *)censusID andSecret:(NSString *)publisherSalt;

+ (CSCensus *)census;


@end
