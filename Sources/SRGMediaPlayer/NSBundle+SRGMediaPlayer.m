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
