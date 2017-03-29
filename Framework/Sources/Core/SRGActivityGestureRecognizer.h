//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Gesture recognizer which detects all kinds of user activities and call the associated action on its target if any 
 *  activity is detected.
 *
 *  Simply add to any view onto which user activity must be reported, and bind to an associated target and action.
 */
@interface SRGActivityGestureRecognizer : UIGestureRecognizer

@end

NS_ASSUME_NONNULL_END
