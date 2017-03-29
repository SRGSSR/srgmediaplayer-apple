//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Templates for various player icons.
 */
@interface SRGMediaPlayerIconTemplate : NSObject

/**
 *  Play image.
 *
 *  @param size  The desired image size.
 */
+ (UIImage *)playImageWithSize:(CGSize)size;

/**
 *  Pause image.
 *
 *  @param size  The desired image size.
 */
+ (UIImage *)pauseImageWithSize:(CGSize)size;

/**
 *  Stop image.
 *
 *  @param size  The desired image size.
 */
+ (UIImage *)stopImageWithSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
