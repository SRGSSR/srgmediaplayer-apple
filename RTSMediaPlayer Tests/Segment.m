//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic) CMTimeRange timeRange;

@end

@implementation Segment

#pragma mark - Object lifecycle

- (instancetype)initWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
	if (self = [super init])
	{
		self.timeRange = timeRange;
		self.name = name;
		
		self.blocked = NO;
		self.visible = YES;
	}
	return self;
}

@end
