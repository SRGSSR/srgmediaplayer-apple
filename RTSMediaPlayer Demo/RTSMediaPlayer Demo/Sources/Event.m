//
//  Created by Samuel Défago on 01.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "Event.h"

@interface Event ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *identifier;

@end

@implementation Event

#pragma mark - Object lifecycle

- (instancetype) initWithTime:(CMTime)time title:(NSString *)title identifier:(NSString *)identifier
{
	if (self = [super initWithTime:time])
	{
		self.title = title;
		self.identifier = identifier;
	}
	return self;
}

#pragma mark - Getters and setters

- (NSURL *) imageURL
{
	NSString *imageURLString = [NSString stringWithFormat:@"http://test.event.api.swisstxt.ch:80/v1/image/byId/%@", self.identifier];
	return [NSURL URLWithString:imageURLString];
}

#pragma mark - Description

- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@: %p; time: %@; title: %@; identifier: %@>",
			[self class],
			self,
			@(CMTimeGetSeconds(self.time)),
			self.title,
			self.identifier];
}

@end
