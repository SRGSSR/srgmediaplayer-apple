//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MPVolumeView+SRGMediaPlayer.h"

@implementation MPVolumeView (SRGMediaPlayer)

- (UIButton *)srg_airplayButton
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:[UIButton class]];
    }];
    return [self.subviews filteredArrayUsingPredicate:predicate].firstObject;
}

@end
