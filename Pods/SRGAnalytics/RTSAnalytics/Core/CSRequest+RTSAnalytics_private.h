//
//  CSRequest+RTSNotification.h
//  RTSMobileKit
//
//  Created by Cédric Luthi on 26.08.14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  The `object` is the `NSURLRequest` that was sent to comScore.
 *  The `userInfo` contains the `ComScoreRequestSuccessUserInfoKey` which is a BOOL NSNumber indicating if the request succeeded or failed.
 *  The `userInfo` also contains the `ComScoreRequestLabelsUserInfoKey` which is a NSDictionary representing all the labels.
 */
extern NSString * const RTSAnalyticsComScoreRequestDidFinishNotification;
extern NSString * const RTSAnalyticsComScoreRequestSuccessUserInfoKey;
extern NSString * const RTSAnalyticsComScoreRequestLabelsUserInfoKey;

/**
 *  The comScore SDK does not expose success/failure callbacks when sending requests so we hook here to provide a notification.
 *  This notification may be used for logging and integration tests.
 */
@interface CSRequest : NSObject
- (BOOL)send;
@end

@interface CSRequest (RTSNotification)
// The implementation swizzles `send` for posting the `ComScoreRequestDidFinishNotification` notification.
@end
