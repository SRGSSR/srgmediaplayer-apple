//
//  Created by Cédric Foellmi on 31/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

/**
 *  `RTSAnalyticsVersion` MUST match the Pod tag version!
 */
#define kRTSAnalyticsVersion @"0.0.1"

#import "RTSAnalyticsTracker.h"
#import "RTSAnalyticsTracker+Logging.h"

#import "RTSAnalyticsPageViewDataSource.h"

#import "UIViewController+RTSAnalytics.h"

#if __has_include("RTSAnalyticsMediaPlayer.h")
#import "RTSAnalyticsMediaPlayer.h"
#endif