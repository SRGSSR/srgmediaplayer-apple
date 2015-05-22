//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerSegment.h"

@interface RTSMediaPlayerSegment ()

@property (nonatomic) CMTime startTime;
@property (nonatomic) CMTime endTime;

@end

@implementation RTSMediaPlayerSegment

#pragma mark - Object lifecycle

- (instancetype) initWithStartTime:(CMTime)startTime endTime:(CMTime)endTime
{
	if (self = [super init])
	{
		self.startTime = startTime;
		self.endTime = endTime;
	}
	return self;
}

#pragma mark - Description

- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@: %p; startTime: %@; endTime: %@>",
			[self class],
			self,
			@(CMTimeGetSeconds(self.startTime)),
			@(CMTimeGetSeconds(self.endTime))];
}

@end
