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

NSString *SRGMediaPlayerApplicationLocalization(void)
{
    return NSBundle.mainBundle.preferredLocalizations.firstObject;
}

@implementation NSBundle (SRGMediaPlayer)

+ (NSBundle *)srg_mediaPlayerBundle
{
    static NSBundle *s_bundle;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        NSString *bundlePath = [[NSBundle bundleForClass:SRGMediaPlayerController.class].bundlePath stringByAppendingPathComponent:@"SRGMediaPlayer.bundle"];
        s_bundle = [NSBundle bundleWithPath:bundlePath];
        NSAssert(s_bundle, @"Please add SRGMediaPlayer.bundle to your project resources");
    });
    return s_bundle;
}

@end
