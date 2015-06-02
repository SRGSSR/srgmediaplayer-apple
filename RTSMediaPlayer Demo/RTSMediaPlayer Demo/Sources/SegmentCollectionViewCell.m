//
//  SegmentCollectionViewCell.m
//  SRGIntegrationLayerDataProvider Demo
//
//  Created by Samuel Defago on 21.05.15.
//  Copyright (c) 2015 SRG. All rights reserved.
//

#import "SegmentCollectionViewCell.h"

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

@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *timestampLabel;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@end

@implementation SegmentCollectionViewCell

#pragma mark - Getters and setters

- (void)setSegment:(Segment *)segment
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
	
	if (segment.thumbnailURL) {
		dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^(void) {
			NSData *data = [[NSData alloc] initWithContentsOfURL:segment.thumbnailURL];
			UIImage *image = [[UIImage alloc] initWithData:data];
			
			if (image) {
				dispatch_async( dispatch_get_main_queue(), ^(void){
					self.imageView.image = image;
				});
			}
		});
	}
	
    self.titleLabel.text = segment.title;
    self.durationLabel.text = sexagesimalDurationStringFromValue(CMTimeGetSeconds(segment.segmentTimeRange.duration));
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
	CMTimeRange r = self.segment.segmentTimeRange;
    float progress = (CMTimeGetSeconds(time) - CMTimeGetSeconds(r.start)) / (CMTimeGetSeconds(CMTimeAdd(r.start, r.duration)) - CMTimeGetSeconds(r.start));
    progress = fminf(1.f, fmaxf(0.f, progress));
    
    self.progressView.progress = progress;
    self.backgroundColor = (progress != 0.f && progress != 1.f) ? [UIColor colorWithRed:128.0 / 256.0 green:0.0 / 256.0 blue:0.0 / 256.0 alpha:1.0] : [UIColor blackColor];
}

@end
