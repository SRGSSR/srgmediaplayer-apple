//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineEvent.h"

@interface RTSTimelineEvent ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic) CMTime time;

@end

@implementation RTSTimelineEvent

- (instancetype) initWithTitle:(NSString *)title time:(CMTime)time
{
	NSParameterAssert(title);
	
	if (self = [super init])
	{
		self.title = title;
		self.time = time;
	}
	return self;
}

#pragma mark Description

- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@: %p; title: %@; time: %@>",
			[self class],
			self,
			self.title,
			@(CMTimeGetSeconds(self.time))];
}

@end
