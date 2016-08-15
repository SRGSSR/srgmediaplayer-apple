//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayer.h"

#import "NSBundle+RTSMediaPlayer.h"

NSString * SRGMediaPlayerMarketingVersion(void)
{
	return [NSBundle RTSMediaPlayerBundle].infoDictionary[@"CFBundleVersion"];
}
