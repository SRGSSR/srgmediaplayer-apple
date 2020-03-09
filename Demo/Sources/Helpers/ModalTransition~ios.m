//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ModalTransition.h"

// For implementation details, see
//   https://developer.apple.com/library/content/featuredarticles/ViewControllerPGforiPhoneOS/CustomizingtheTransitionAnimations.html#//apple_ref/doc/uid/TP40007457-CH16-SW1

@interface ModalTransition ()

@property (nonatomic) BOOL presentation;
@property (nonatomic) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic) CGFloat progress;

@property (nonatomic, weak) UIView *dimmingView;

@end

@implementation ModalTransition

#pragma mark Object lifecycle

- (instancetype)initForPresentation:(BOOL)presentation
{
    if (self = [super init]) {
        self.presentation = presentation;
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initForPresentation:YES];
}

#pragma mark Getters and setters

- (BOOL)wasCancelled
{
    return self.transitionContext.transitionWasCancelled;
}

#pragma mark Common transition implementation

- (void)setupTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSParameterAssert(transitionContext);
    
    UIView *containerView = [transitionContext containerView];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    NSAssert(fromView && toView, @"Do not use UIModalPresentationCustom for presentation");
    
    UIView *dimmingView = [[UIView alloc] initWithFrame:containerView.bounds];
    dimmingView.frame = containerView.bounds;
    dimmingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    dimmingView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5f];
    self.dimmingView = dimmingView;
    
    if (self.presentation) {
        [containerView addSubview:toView];
        [containerView insertSubview:dimmingView aboveSubview:fromView];
    }
    else {
        [containerView insertSubview:toView belowSubview:fromView];
        [containerView insertSubview:dimmingView aboveSubview:toView];
    }
    
    [self updateTransition:transitionContext withProgress:0.f];
}

- (void)updateTransition:(id<UIViewControllerContextTransitioning>)transitionContext withProgress:(CGFloat)progress
{
    NSParameterAssert(transitionContext);
    
    UIView *containerView = [transitionContext containerView];
    
    // Clamp to [0; 1]
    progress = fmaxf(fminf(1.f, progress), 0.f);
    
    if (self.presentation) {
        UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        fromView.frame = containerView.bounds;
        
        UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        toView.frame = CGRectMake(0.f,
                                  (1.f - progress) * CGRectGetMaxY(containerView.bounds),
                                  CGRectGetWidth(containerView.bounds),
                                  CGRectGetHeight(containerView.bounds));
        
        self.dimmingView.alpha = progress;
    }
    else {
        UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        fromView.frame = CGRectMake(0.f,
                                    progress * CGRectGetMaxY(containerView.bounds),
                                    CGRectGetWidth(containerView.bounds),
                                    CGRectGetHeight(containerView.bounds));
        
        UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        toView.frame = containerView.bounds;
        
        self.dimmingView.alpha = 1.f - progress;
    }
}

- (void)completeTransition:(id<UIViewControllerContextTransitioning>)transitionContext success:(BOOL)success
{
    NSParameterAssert(transitionContext);
    
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    
    if (! success) {
        [toView removeFromSuperview];
    }
    
    [self.dimmingView removeFromSuperview];
    
    [transitionContext completeTransition:success];
}

#pragma mark Interactive transition

- (void)updateInteractiveTransitionWithProgress:(CGFloat)progress
{
    if (! self.transitionContext) {
        return;
    }
    
    [self.transitionContext updateInteractiveTransition:progress];
    [self updateTransition:self.transitionContext withProgress:progress];
}

- (void)cancelInteractiveTransition
{
    if (! self.transitionContext) {
        return;
    }
    
    [self.transitionContext cancelInteractiveTransition];
    
    [UIView animateWithDuration:0.2 animations:^{
        [self updateTransition:self.transitionContext withProgress:0.f];
    } completion:^(BOOL finished) {
        BOOL success = ! [self.transitionContext transitionWasCancelled];
        [self completeTransition:self.transitionContext success:success];
    }];
}

- (void)finishInteractiveTransition
{
    if (! self.transitionContext) {
        return;
    }
    
    [self.transitionContext finishInteractiveTransition];
    
    [UIView animateWithDuration:0.2 animations:^{
        [self updateTransition:self.transitionContext withProgress:1.f];
    } completion:^(BOOL finished) {
        BOOL success = ! [self.transitionContext transitionWasCancelled];
        [self completeTransition:self.transitionContext success:success];
    }];
}

#pragma mark UIViewControllerAnimatedTransitioning protocol (non-interactive transition)

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSParameterAssert(transitionContext);
    
    [self setupTransition:transitionContext];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        [self updateTransition:transitionContext withProgress:1.f];
    } completion:^(BOOL finished) {
        BOOL success = ! [transitionContext transitionWasCancelled];
        [self completeTransition:transitionContext success:success];
    }];
}

#pragma mark UIViewControllerInteractiveTransitioning protocol (interactive transition)

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSParameterAssert(transitionContext);
    
    [self setupTransition:transitionContext];
    self.transitionContext = transitionContext;
}

- (UIViewAnimationCurve)completionCurve
{
    return UIViewAnimationCurveEaseInOut;
}

@end
