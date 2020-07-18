//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayer.h"

#import "NSBundle+SRGMediaPlayer.h"

NSString *SRGMediaPlayerMarketingVersion(void)
{
    return SWIFTPM_MODULE_BUNDLE.infoDictionary[@"CFBundleShortVersionString"];
}
