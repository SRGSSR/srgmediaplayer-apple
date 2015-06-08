//
//  Created by Frédéric Humbert-Droz on 09/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  The `RTSAnalyticsPageViewDataSource` groups methods that are used for view event measurement.
 * 
 *  If the UIViewController conforms to this protocol, the tracker will send a view event to Comscore and Netmetrix at each `-viewDidAppear:`
 */
@protocol RTSAnalyticsPageViewDataSource <NSObject>

/**
 *  Returns the page view title to be sent in `srg_title` label for view event measurement.
 *
 *  @return the page view title. Empty or nil value will be replaced by `Untitled` value.
 *
 *  @discussion The title will be "normalized" using `-(NSString *)comScoreFormattedString` from `NSString+RTSAnalyticsUtils` category.
 */
- (NSString *)pageViewTitle;

@optional

/**
 *  Returns the levels to be sent for view event measurement. Each level will be added as `srg_n...` label. The tracker will also add a label named `category`
 *  containing the concatenation of all levels separated with a `.` (srg_n1.srg_n2...).
 *
 *  If the page view levels array is nil or empty, the tracker will add one default level `srg_n1` label and a `category` label with value `app`. 
 *  Up to 10 levels can be set, more levels will be dropped 
 *
 *  @return an array of string.
 *
 *  @discussion Each level value will be "normalized" using `-(NSString *)comScoreFormattedString` from `NSString+RTSAnalyticsUtils` category.
 */
- (NSArray *)pageViewLevels;

/**
 *  Returns a dictionary of key values that will be set a labels when sending view events. 
 *  When returning custom labels, beware persistent labels can be overrided by those custom labels values.
 *
 *  @return a dictionary of labels.
 */
- (NSDictionary *)pageViewCustomLabels;

/**
 *  Returns the value specifying weither the view controller has been opened from a push notification or not.
 *  The tracker will set the `srg_ap_push` label value to `1` if true, `0` otherwise.
 *
 *  @return YES if the presented view controller has been opened from a push notification, NO otherwise. Default value is NO.
 */
- (BOOL)pageViewFromPushNotification;

@end
