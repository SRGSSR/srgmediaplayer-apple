//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

@implementation Segment

- (instancetype)initWithIdentifier:(NSString *)identifier timeRange:(CMTimeRange)timeRange fullLength:(BOOL)fullLength
{
	if (self = [super init])
	{
		self.timeRange = timeRange;
		self.segmentIdentifier = identifier;
		self.fullLength = fullLength;
		self.blocked = NO;
		self.visible = YES;
	}
	return self;
}

@end
