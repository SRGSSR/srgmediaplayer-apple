//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+RTSMediaPlayer.h"

#import "RTSMediaPlayerController.h"

@implementation NSBundle (RTSMediaPlayer)

+ (instancetype)rts_mediaPlayerBundle
{
    static NSBundle *bundle;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        bundle = [NSBundle bundleForClass:[RTSMediaPlayerController class]];
    });
    return bundle;
}

@end
