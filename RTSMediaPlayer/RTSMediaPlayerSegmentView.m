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
		NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"segmentStartTime" ascending:YES comparator:^NSComparisonResult(NSValue *timeValue1, NSValue *timeValue2) {
			CMTime time1 = [timeValue1 CMTimeValue];
			CMTime time2 = [timeValue2 CMTimeValue];
			return CMTimeCompare(time1, time2);
		}];
		[self reloadWithSegments:[segments sortedArrayUsingDescriptors:@[sortDescriptor]]];
	}];
}

#pragma mark - Subclassing hooks

- (void) reloadWithSegments:(NSArray *)segments
{}

@end
