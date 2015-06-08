//
//  Created by Frédéric Humbert-Droz on 09/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  The implementation swizzles `viewDidAppear:` for automatic analytics
 */
@interface UIViewController (RTSAnalytics)

/**
 *  Call this method to track view events manually when content changes (by ex.: filtering data, changing part of the view, ...)
 */
- (void)trackPageView;

@end
