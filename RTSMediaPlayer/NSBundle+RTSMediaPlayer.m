//
//  Created by Cédric Luthi on 09.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
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
