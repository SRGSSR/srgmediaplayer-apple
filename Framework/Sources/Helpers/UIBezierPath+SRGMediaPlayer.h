//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBezierPath (SRGMediaPlayer)

/**
 *  Return the receiver as an image with the given tint color.
 *
 *  @param color The tint color.
 */
- (UIImage *)srg_imageWithColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
