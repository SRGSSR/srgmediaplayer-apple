//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayer.h"

#import "NSBundle+SRGMediaPlayer.h"

NSString *SRGMediaPlayerMarketingVersion(void)
{
    return [NSBundle srg_mediaPlayerBundle].infoDictionary[@"CFBundleShortVersionString"];
}
