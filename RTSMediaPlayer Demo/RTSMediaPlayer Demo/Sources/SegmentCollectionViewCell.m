//
//  Created by Samuel Défago on 01.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "SegmentCollectionViewCell.h"

#import <SDWebImage/UIImageView+WebCache.h>

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
	
	self.iconImageView.image = segment.segmentIconImage;
	self.titleLabel.text = segment.title;
	
	static NSDateFormatter *s_dateFormatter;
	static dispatch_once_t s_onceToken;
	dispatch_once(&s_onceToken, ^{
		s_dateFormatter = [[NSDateFormatter alloc] init];
		[s_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[s_dateFormatter setDateStyle:NSDateFormatterNoStyle];
	});
	self.timestampLabel.text = [NSString stringWithFormat:@"at %@", [s_dateFormatter stringFromDate:segment.date]];
	
	[self.imageView sd_setImageWithURL:segment.thumbnailURL];
}

@end
