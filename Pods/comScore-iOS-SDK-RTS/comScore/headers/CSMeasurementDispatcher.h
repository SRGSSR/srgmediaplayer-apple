//
//  CSMeasurementDispatcher.h
//  comScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

#import "CSEventType.h"

@class CSCore;
@class CSAggregateMeasurement;
@class CSMeasurement;

@interface CSMeasurementDispatcher : NSObject {
    CSCore *_core;
    CSAggregateMeasurement *_aggregateData;
    int _eventCounter;
    double _secondEventCheckOffset;
    int _secondEventCheckCounter;
    double _dayEventCheckOffset;
    int _dayEventCheckCounter;
}

- (id)initWithCore:(CSCore *)core;

/** Enqueues a measurement in the task queue to be executed in the background
 *   @evenType Type of the measurement to create
 *   @pixelURL url to send the measurement
 *   @cache Indicates if the measurement should be send or cached
 */
- (void)send:(CSApplicationEventType)eventType
      labels:(NSDictionary *)labels
    pixelURL:(NSString *)pixelURL
       cache:(BOOL)cache
  background:(BOOL)background;

/**
 * Loads all the event limits from the storage
 */
- (void)loadEventData;

@end
