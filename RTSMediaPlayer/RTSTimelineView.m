//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSTimelineView.h"

@implementation RTSTimelineView

- (void) reloadData
{
	NSInteger numberOfEvents = [self.dataSource numberOfEventsInTimelineView:self];
	for (NSInteger i = 0; i < numberOfEvents; ++i)
	{
		// RTSTimelineEvent *event = [self.dataSource timelineView:self eventAtIndex:i];
		
	}
}

@end
