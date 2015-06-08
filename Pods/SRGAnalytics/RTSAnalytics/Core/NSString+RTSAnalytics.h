//
//  NSString+RTSAnlyticsUtils.h
//  RTSAnalytics
//
//  Created by Cédric Foellmi on 26/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (RTSAnalytics)

- (NSString *)comScoreTitleFormattedString;
- (NSString *)comScoreFormattedString;
- (NSString *)truncateAndAddEllipsisForStatistics;
- (NSString *)truncateAndAddEllipsis:(int)maxLength;

@end
