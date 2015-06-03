//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "NSBundle+RTSMediaPlayer.h"

@implementation NSBundle (RTSMediaPlayer)

+ (instancetype) RTSMediaPlayerBundle
{
	static NSBundle *mediaPlayerBundle;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		NSURL *mediaPlayerBundleURL = [[NSBundle mainBundle] URLForResource:@"RTSMediaPlayer" withExtension:@"bundle"];
		NSAssert(mediaPlayerBundleURL != nil, @"RTSMediaPlayer.bundle not found in the main bundle's resources");
		mediaPlayerBundle = [NSBundle bundleWithURL:mediaPlayerBundleURL];
	});
	return mediaPlayerBundle;
}

@end
