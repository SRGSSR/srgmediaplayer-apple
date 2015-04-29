//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineEvent.h"

@interface RTSTimelineEvent ()

@property (nonatomic) CMTime time;

@end

@implementation RTSTimelineEvent

- (instancetype) initWithTime:(CMTime)time
{
	if (self = [super init])
	{
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
