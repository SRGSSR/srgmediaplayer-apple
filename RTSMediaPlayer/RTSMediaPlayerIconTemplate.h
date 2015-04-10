//
//  Created by Cédric Luthi on 10.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RTSMediaPlayerIconTemplate : NSObject

+ (UIImage *) playImageWithSize:(CGSize)size color:(UIColor *)color;
+ (UIImage *) pauseImageWithSize:(CGSize)size color:(UIColor *)color;

@end
