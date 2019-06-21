//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVRoutePickerView (SRGMediaPlayer)

/**
 *  Return the AirPlay button within the volume view.
 */
@property (nonatomic, readonly) UIButton *srg_airPlayButton;

/**
 *  Set to `YES` to hide the original layers the button icon is made of.
 */
@property (nonatomic) BOOL srg_isOriginalIconHidden;

@end

NS_ASSUME_NONNULL_END
