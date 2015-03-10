//
//  Created by Frédéric Humbert-Droz on 06/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSOverlayView.h"

@implementation RTSOverlayView

#pragma mark - RTSOverlayViewProtocol

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController overlayHidden:(BOOL)hidden
{
	if (hidden)
		[self hide];
	else
		[self show];
}



#pragma mark - Actions

- (void) show
{
	self.hidden = NO;
	[UIView animateWithDuration:0.3f animations:^{
		self.alpha = 1.0f;
	} completion:^(BOOL finished) {
		
	}];
}

- (void) hide
{
	[UIView animateWithDuration:0.3f animations:^{
		self.alpha = 0.0f;
	} completion:^(BOOL finished) {
		self.hidden = YES;
	}];
}



#pragma mark - Touch handler

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	NSLog(@"RTSOverlayView touch began");
}

@end
