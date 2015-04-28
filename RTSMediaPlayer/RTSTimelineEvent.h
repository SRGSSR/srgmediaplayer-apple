//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RTSTimelineEvent : NSObject

+ (instancetype) timelineEventWithTitle:(NSString *)title iconImage:(UIImage *)iconImage;
+ (instancetype) timelineEventWithTitle:(NSString *)title;
+ (instancetype) timelineEventWithIconImage:(UIImage *)iconImage;

- (instancetype) initWithTitle:(NSString *)title iconImage:(UIImage *)iconImage;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly) UIImage *iconImage;

@end
