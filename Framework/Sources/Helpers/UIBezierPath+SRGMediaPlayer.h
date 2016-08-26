//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (SRGMediaPlayer)

/**
 *  Return the receiver as an image with the given tint color
 *
 *  @param color The tint color
 */
- (UIImage *)srg_imageWithColor:(UIColor *)color;

@end
