//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineEvent.h"

@interface RTSTimelineEvent ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic) UIImage *iconImage;

@end

@implementation RTSTimelineEvent

+ (instancetype) timelineEventWithTitle:(NSString *)title iconImage:(UIImage *)iconImage
{
	return [[[self class] alloc] initWithTitle:title iconImage:iconImage];
}

+ (instancetype) timelineEventWithTitle:(NSString *)title
{
	return [[[self class] alloc] initWithTitle:title iconImage:nil];
}

+ (instancetype) timelineEventWithIconImage:(UIImage *)iconImage
{
	return [[[self class] alloc] initWithTitle:nil iconImage:iconImage];
}

- (instancetype) initWithTitle:(NSString *)title iconImage:(UIImage *)iconImage
{
	if (self = [super init])
	{
		self.title = title;
		self.iconImage = iconImage;
	}
	return self;
}

#pragma mark Description

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p; title: %@; iconImage: %@>",
			[self class],
			self,
			self.title,
			self.iconImage];
}

@end
