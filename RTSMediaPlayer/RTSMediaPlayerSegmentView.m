//
//  Created by Samuel Défago on 22.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerSegmentView.h"

#import "RTSMediaPlayerController.h"

@implementation RTSMediaPlayerSegmentView

#pragma mark - Data

- (void) reloadSegmentsForIdentifier:(NSString *)identifier
{
	[self.dataSource view:self segmentsForIdentifier:identifier completionHandler:^(NSArray *segments, NSError *error) {
		NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"segmentTimeRange" ascending:YES comparator:^NSComparisonResult(NSValue *timeRangeValue1, NSValue *timeRangeValue2) {
			CMTimeRange timeRange1 = [timeRangeValue1 CMTimeRangeValue];
			CMTimeRange timeRange2 = [timeRangeValue2 CMTimeRangeValue];
			return CMTimeCompare(timeRange1.start, timeRange2.start);
		}];
		[self reloadWithSegments:[segments sortedArrayUsingDescriptors:@[sortDescriptor]]];
	}];
}

#pragma mark - Subclassing hooks

- (void) reloadWithSegments:(NSArray *)segments
{}

@end
