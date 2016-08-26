//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Templates for various player icons
 */
@interface SRGMediaPlayerIconTemplate : NSObject

/**
 *  Play image
 *
 *  @param size  The desired image size
 *  @param color The desired tint color (black if nil)
 */
+ (UIImage *)playImageWithSize:(CGSize)size color:(nullable UIColor *)color;

/**
 *  Pause image
 *
 *  @param size  The desired image size
 *  @param color The desired tint color (black if nil)
 */
+ (UIImage *)pauseImageWithSize:(CGSize)size color:(nullable UIColor *)color;

/**
 *  Stop image
 *
 *  @param size  The desired image size
 *  @param color The desired tint color (black if nil)
 */
+ (UIImage *)stopImageWithSize:(CGSize)size color:(nullable UIColor *)color;

@end

NS_ASSUME_NONNULL_END
