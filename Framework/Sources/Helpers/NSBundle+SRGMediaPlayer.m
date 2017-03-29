//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+SRGMediaPlayer.h"

#import "SRGMediaPlayerController.h"

@implementation NSBundle (SRGMediaPlayer)

+ (NSBundle *)srg_mediaPlayerBundle
{
    static NSBundle *bundle;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        bundle = [NSBundle bundleForClass:[SRGMediaPlayerController class]];
    });
    return bundle;
}

@end
