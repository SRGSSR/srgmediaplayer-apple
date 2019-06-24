//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVRoutePickerView+SRGMediaPlayer.h"

static CALayer *SRGAirPlayIconLayerInLayer(CALayer *layer)
{
    if ([layer.name containsString:@"AirPlay"]) {
        return layer;
    }
    
    for (CALayer *sublayer in layer.sublayers) {
        CALayer *iconLayer = SRGAirPlayIconLayerInLayer(sublayer);
        if (iconLayer) {
            return iconLayer;
        }
    }
    
    return nil;
}

@implementation AVRoutePickerView (SRGMediaPlayer)

#pragma mark Getters and setters

- (UIButton *)srg_airPlayButton
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UIView * _Nullable view, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [view isKindOfClass:UIButton.class];
    }];
    return [self.subviews filteredArrayUsingPredicate:predicate].firstObject;
}

- (BOOL)srg_isOriginalIconHidden
{
    CALayer *iconLayer = SRGAirPlayIconLayerInLayer(self.layer);
    return iconLayer.hidden;
}

- (void)setSrg_isOriginalIconHidden:(BOOL)hidden
{
    CALayer *iconLayer = SRGAirPlayIconLayerInLayer(self.layer);
    iconLayer.hidden = hidden;
}

@end
