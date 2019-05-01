//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSLocale+SRGMediaPlayer.h"

#import "SRGMediaPlayerController.h"

@implementation NSLocale (SRGMediaPlayer)

- (NSString *)srg_languageCode
{
    if (@available(iOS 10, *)) {
        return self.languageCode;
    }
    else {
        return [self.localeIdentifier componentsSeparatedByString:@"_"].firstObject;
    }
}

@end
