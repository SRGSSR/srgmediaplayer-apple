//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSActivityGestureRecognizer.h"

#import <UIKit/UIGestureRecognizerSubclass.h>

// Heavily "inspired" by MPActivityGestureRecognizer from the MediaPlayer framework
@implementation RTSActivityGestureRecognizer

- (instancetype) initWithTarget:(id)target action:(SEL)action
{
	if (!(self = [super initWithTarget:target action:action]))
		return nil;
	
	self.cancelsTouchesInView = NO;
	self.delaysTouchesEnded = NO;
	
	return self;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self stopReportingOngoingActivity];
	[self reportOngoingActivity];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.state = UIGestureRecognizerStateChanged;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// The MPActivityGestureRecognizer does it a bit differently, see -[MPActivityGestureRecognizer _touchesTerminated:withEvent:]
	[self stopReportingOngoingActivity];
	self.state = UIGestureRecognizerStateEnded;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self stopReportingOngoingActivity];
	self.state = UIGestureRecognizerStateCancelled;
}

- (void) reportOngoingActivity
{
	self.state = UIGestureRecognizerStateBegan;
	[self performSelector:_cmd withObject:nil afterDelay:1];
}

- (void) stopReportingOngoingActivity
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reportOngoingActivity) object:nil];
}

@end
