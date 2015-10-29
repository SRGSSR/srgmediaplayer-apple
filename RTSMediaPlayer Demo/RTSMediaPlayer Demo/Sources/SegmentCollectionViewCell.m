//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import "SegmentCollectionViewCell.h"

@interface SegmentCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;
@property (nonatomic, weak) IBOutlet UILabel *timestampLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@end

@implementation SegmentCollectionViewCell

#pragma mark - Getters and setters

- (void)setSegment:(Segment *)segment
{
	_segment = segment;
	
	self.titleLabel.text = segment.name;
	
	if (!CMTIMERANGE_IS_EMPTY(segment.timeRange)) {
		self.durationLabel.hidden = NO;
		self.durationLabel.text = segment.durationString;
	}
	else {
		self.durationLabel.hidden = YES;
	}
	
	self.timestampLabel.text = segment.timestampString;
	[self.imageView sd_setImageWithURL:segment.thumbnailURL];
	
	self.alpha = (segment.isBlocked) ? 0.5 : 1.0;
}

#pragma mark - Overrides

- (void)prepareForReuse
{
	[super prepareForReuse];
	self.progressView.progress = 0.f;
}

#pragma mark - UI

- (void)updateAppearanceWithTime:(CMTime)time identifier:(NSString *)identifier
{
	if ([self.segment.segmentIdentifier isEqualToString:identifier]) {
		CMTimeRange r = self.segment.timeRange;
		float progress = (CMTimeGetSeconds(time) - CMTimeGetSeconds(r.start)) / (CMTimeGetSeconds(CMTimeAdd(r.start, r.duration)) - CMTimeGetSeconds(r.start));
		progress = fminf(1.f, fmaxf(0.f, progress));
		
		self.progressView.progress = progress;
		self.backgroundColor = (progress != 0.f && progress != 1.f) ? [UIColor colorWithRed:128.0 / 256.0 green:0.0 / 256.0 blue:0.0 / 256.0 alpha:1.0] : [UIColor blackColor];
	}
	else {
		self.progressView.progress = 0.;
		self.backgroundColor = [UIColor blackColor];
	}
	
}

@end