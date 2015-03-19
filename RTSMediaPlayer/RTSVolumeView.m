//
//  Created by Frédéric Humbert-Droz on 06/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSVolumeView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface RTSVolumeView ()
@property MPVolumeView *mpVolumeView;
@end

@implementation RTSVolumeView

- (void) awakeFromNib
{
	self.mpVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
	self.mpVolumeView.showsRouteButton = NO;
	self.mpVolumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self addSubview:self.mpVolumeView];
}

- (void) setHidden:(BOOL)hidden
{
	[super setHidden:hidden];
	[self.mpVolumeView setHidden:hidden];
}

@end
