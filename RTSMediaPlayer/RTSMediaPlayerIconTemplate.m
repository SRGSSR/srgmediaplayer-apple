//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerIconTemplate.h"

@implementation RTSMediaPlayerIconTemplate

+ (UIImage *) imageWithBezierPath:(UIBezierPath *)bezierPath size:(CGSize)size color:(UIColor *)color
{
	CGFloat scale = [UIScreen mainScreen].scale;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, size.width * scale, size.height * scale, 8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(colorSpace);
	
	CGContextScaleCTM(context, scale, scale);
	CGContextAddPath(context, bezierPath.CGPath);
	CGContextSetFillColorWithColor(context, color.CGColor ?: [UIColor blackColor].CGColor);
	CGContextFillPath(context);
	
	CGImageRef imageRef = CGBitmapContextCreateImage(context);
	UIImage *image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
	CGImageRelease(imageRef);
	CGContextRelease(context);

	return image;
}

#pragma mark - Bezier Paths

+ (UIBezierPath *) playBezierPathWithSize:(CGSize)size
{
	UIBezierPath *playBezierPath;
	playBezierPath = [UIBezierPath bezierPath];
	[playBezierPath moveToPoint:CGPointMake(0, 0)];
	[playBezierPath addLineToPoint:CGPointMake(size.width, size.height / 2)];
	[playBezierPath addLineToPoint:CGPointMake(0, size.height)];
	[playBezierPath closePath];
	return playBezierPath;
}

+ (UIBezierPath *) pauseBezierPathWithSize:(CGSize)size
{
	CGFloat middle = CGRectGetMidX((CGRect){CGPointZero, size});
	CGFloat margin = middle * 1/3;
	CGFloat width = middle - margin;
	
	UIBezierPath *pauseBezierPath = [UIBezierPath bezierPath];
	[pauseBezierPath moveToPoint:CGPointMake(margin / 2, 0)];
	[pauseBezierPath addLineToPoint:CGPointMake(width, 0)];
	[pauseBezierPath addLineToPoint:CGPointMake(width, size.height)];
	[pauseBezierPath addLineToPoint:CGPointMake(margin / 2, size.height)];
	[pauseBezierPath closePath];
	
	[pauseBezierPath moveToPoint:CGPointMake(middle + margin / 2, 0)];
	[pauseBezierPath addLineToPoint:CGPointMake(middle + width, 0)];
	[pauseBezierPath addLineToPoint:CGPointMake(middle + width, size.height)];
	[pauseBezierPath addLineToPoint:CGPointMake(middle + margin / 2, size.height)];
	[pauseBezierPath closePath];
	
	return pauseBezierPath;
}

#pragma mark - Images

+ (UIImage *) playImageWithSize:(CGSize)size color:(UIColor *)color
{
	return [self imageWithBezierPath:[self playBezierPathWithSize:size] size:size color:color];
}

+ (UIImage *) pauseImageWithSize:(CGSize)size color:(UIColor *)color
{
	return [self imageWithBezierPath:[self pauseBezierPathWithSize:size] size:size color:color];
}

@end
