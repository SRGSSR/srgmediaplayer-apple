//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Manage a custom modal transition.
 */
@interface ModalTransition : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

/**
 *  Create a modal transition. Set presentation to `YES` for the presentation version, `NO` for dismissal.
 */
- (instancetype)initForPresentation:(BOOL)presentation;

/**
 *  Update the interactive transition progress
 */
- (void)updateInteractiveTransitionWithProgress:(CGFloat)progress;

/**
 *  Finish the interactive transition with the specified initial animation velocity
 */
- (void)finishInteractiveTransitionWithVelocity:(CGFloat)velocity;

/**
 *  Cancel the interactive transition with the specified initial animation velocity
 */
- (void)cancelInteractiveTransitionWithVelocity:(CGFloat)velocity;

@end

NS_ASSUME_NONNULL_END
