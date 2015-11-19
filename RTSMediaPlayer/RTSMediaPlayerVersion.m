//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerVersion.h"

#import "RTSMediaPlayerLogger.h"

NSString * const RTSMediaPlayerVersion(void)
{
#ifdef RTS_ANALYTICS_VERSION
    return @(OS_STRINGIFY(RTS_MEDIA_PLAYER_VERSION));
#else
    RTSMediaPlayerLogWarning(@"No explicit version has been specified, set to 'dev'. Compile the project with a preprocessor "
                             "macro called RTS_MEDIA_PLAYER_VERSION supplying the version number (without quotes)");
    return @"dev";
#endif
}
