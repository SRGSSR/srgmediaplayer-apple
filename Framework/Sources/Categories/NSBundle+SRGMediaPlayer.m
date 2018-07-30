//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+SRGMediaPlayer.h"

#import "SRGMediaPlayerController.h"

NSString *SRGMediaPlayerNonLocalizedString(NSString *string)
{
    return string;
}

@implementation NSBundle (SRGMediaPlayer)

+ (NSBundle *)srg_mediaPlayerBundle
{
    static NSBundle *bundle;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *bundlePath = [[NSBundle bundleForClass:[SRGMediaPlayerController class]].bundlePath stringByAppendingPathComponent:@"SRGMediaPlayer.bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath];
        NSAssert(bundle, @"Please add SRGMediaPlayer.bundle to your project resources");
    });
    return bundle;
}

@end
