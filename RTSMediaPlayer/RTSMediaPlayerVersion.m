//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerVersion.h"

NSString * const RTSMediaPlayerVersion(void)
{
#ifdef RTS_MEDIA_PLAYER_VERSION
    return @(OS_STRINGIFY(RTS_MEDIA_PLAYER_VERSION));
#else
    return @"dev";
#endif
}
