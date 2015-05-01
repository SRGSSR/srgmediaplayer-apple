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

- (instancetype)initWithTime:(CMTime)time title:(NSString *)title identifier:(NSString *)identifier
{
	if (self = [super initWithTime:time])
	{
		self.title = title;
		self.identifier = identifier;
	}
	return self;
}

#pragma mark Description

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p; time: %@; title: %@; identifier: %@>",
			[self class],
			self,
			@(CMTimeGetSeconds(self.time)),
			self.title,
			self.identifier];
}

@end
