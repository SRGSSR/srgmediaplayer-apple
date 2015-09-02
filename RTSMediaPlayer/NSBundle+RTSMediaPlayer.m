//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+RTSMediaPlayer.h"

@implementation NSBundle (RTSMediaPlayer)

+ (instancetype) RTSMediaPlayerBundle
{
	static NSBundle *mediaPlayerBundle;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		NSURL *mediaPlayerBundleURL = [[NSBundle mainBundle] URLForResource:@"SRGMediaPlayer" withExtension:@"bundle"];
		NSAssert(mediaPlayerBundleURL != nil, @"SRGMediaPlayer.bundle not found in the main bundle's resources");
		mediaPlayerBundle = [NSBundle bundleWithURL:mediaPlayerBundleURL];
	});
	return mediaPlayerBundle;
}

@end
