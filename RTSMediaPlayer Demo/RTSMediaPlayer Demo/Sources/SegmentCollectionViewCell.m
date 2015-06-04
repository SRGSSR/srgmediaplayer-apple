//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "SegmentCollectionViewCell.h"

#import "SwissTXTDataSource.h"
#import <SDWebImage/UIImageView+WebCache.h>

#pragma mark - Functions

static NSString *sexagesimalDurationStringFromValue(NSInteger duration)
{
	NSInteger hours = duration / 3600;
	NSInteger minutes = (duration % 3600) / 60;
	NSInteger seconds = (duration % 3600) % 60;
	
	NSString *minutesAndSeconds = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
	
	return (hours > 0) ? [[NSString stringWithFormat:@"%01ld:", (long)hours] stringByAppendingString:minutesAndSeconds] : minutesAndSeconds;
}

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
	
	self.titleLabel.text = segment.title;
	self.durationLabel.text = sexagesimalDurationStringFromValue(CMTimeGetSeconds(segment.timeRange.duration));
	
	NSString *startString = sexagesimalDurationStringFromValue(CMTimeGetSeconds(segment.timeRange.start));
	self.timestampLabel.text = [NSString stringWithFormat:@"%@ (%.0fs)", startString, CMTimeGetSeconds(segment.timeRange.duration)];
	
	[self.imageView sd_setImageWithURL:segment.thumbnailURL];
}

#pragma mark - Overrides

- (void)prepareForReuse
{
	[super prepareForReuse];
	self.progressView.progress = 0.f;
}

#pragma mark - UI

- (void)updateAppearanceWithTime:(CMTime)time
{
	CMTimeRange r = self.segment.timeRange;
	float progress = (CMTimeGetSeconds(time) - CMTimeGetSeconds(r.start)) / (CMTimeGetSeconds(CMTimeAdd(r.start, r.duration)) - CMTimeGetSeconds(r.start));
	progress = fminf(1.f, fmaxf(0.f, progress));
	
	self.progressView.progress = progress;
	self.backgroundColor = (progress != 0.f && progress != 1.f) ? [UIColor colorWithRed:128.0 / 256.0 green:0.0 / 256.0 blue:0.0 / 256.0 alpha:1.0] : [UIColor blackColor];
}

@end