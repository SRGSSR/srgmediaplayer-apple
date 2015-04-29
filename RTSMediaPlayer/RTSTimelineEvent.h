//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RTSTimelineEvent : NSObject

- (instancetype) initWithTitle:(NSString *)title time:(CMTime)time;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly) CMTime time;

@property (nonatomic) UIImage *iconImage;

@end
