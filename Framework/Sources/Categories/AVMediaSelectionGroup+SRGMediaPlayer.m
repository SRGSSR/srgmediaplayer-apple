//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVMediaSelectionGroup+SRGMediaPlayer.h"

@implementation AVMediaSelectionGroup (SRGMediaPlayer)

- (NSArray<AVMediaSelectionOption *> *)srgmediaplayer_languageOptions
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [option.locale objectForKey:NSLocaleLanguageCode] != nil;
    }];
    return [self.options filteredArrayUsingPredicate:predicate];
}

@end
