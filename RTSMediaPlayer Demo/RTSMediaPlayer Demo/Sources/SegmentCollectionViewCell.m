//
//  Created by Samuel Défago on 01.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "SegmentCollectionViewCell.h"

#import <SDWebImage/UIImageView+WebCache.h>

NSString *sexagesimalDurationStringFromValue(double duration)
{
	int hours = (int)round(duration) / 3600;
	int minutes = ((int)round(duration) % 3600) / 60;
	int seconds = ((int)round(duration) % 3600) % 60;
	
	NSString *minutesAndSeconds = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
	
	return (hours > 0) ? [[NSString stringWithFormat:@"%01d:", hours] stringByAppendingString:minutesAndSeconds] : minutesAndSeconds;
}


@interface SegmentCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *timestampLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation SegmentCollectionViewCell

#pragma mark - Setters and getters

- (void) setSegment:(Segment *)segment
{
	_segment = segment;
	
	self.iconImageView.image = segment.iconImage;
	self.titleLabel.text = segment.title;
	
	if (segment.date) {
		static NSDateFormatter *s_dateFormatter;
		static dispatch_once_t s_onceToken;
		dispatch_once(&s_onceToken, ^{
			s_dateFormatter = [[NSDateFormatter alloc] init];
			[s_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
			[s_dateFormatter setDateStyle:NSDateFormatterNoStyle];
		});
		self.timestampLabel.text = [NSString stringWithFormat:@"at %@", [s_dateFormatter stringFromDate:segment.date]];
	}
	else {
		NSString *startString = sexagesimalDurationStringFromValue(CMTimeGetSeconds(segment.segmentTimeRange.start));
		self.timestampLabel.text = [NSString stringWithFormat:@"%@ (%.0fs)", startString, CMTimeGetSeconds(segment.segmentTimeRange.duration)];
	}
	
	[self.imageView sd_setImageWithURL:segment.thumbnailURL];
}

@end
