//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
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
