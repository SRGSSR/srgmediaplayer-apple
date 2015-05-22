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
	return [NSString stringWithFormat:@"<%@: %p; time: %@>",
			[self class],
			self,
			@(CMTimeGetSeconds(self.time))];
}

@end
