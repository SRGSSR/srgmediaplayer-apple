//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+RTSMediaPlayer.h"

#import "RTSMediaPlayerController.h"

@implementation NSBundle (RTSMediaPlayer)

+ (instancetype) RTSMediaPlayerBundle
{
	static NSBundle *mediaPlayerBundle;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		mediaPlayerBundle = [NSBundle bundleForClass:[RTSMediaPlayerController class]];
	});
	return mediaPlayerBundle;
}

@end
