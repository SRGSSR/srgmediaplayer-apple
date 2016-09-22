//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SegmentCollectionViewCell.h"

static NSDateComponentsFormatter *SegmentDurationDateComponentsFormatter(void)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    return s_dateComponentsFormatter;
}

@interface SegmentCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;
@property (nonatomic, weak) IBOutlet UILabel *timestampLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@end

@implementation SegmentCollectionViewCell

#pragma mark Getters and setters

- (void)setSegment:(Segment *)segment
{
    _segment = segment;

    self.titleLabel.text = segment.name;

    if (! CMTIMERANGE_IS_EMPTY(segment.srg_timeRange)) {
        self.durationLabel.hidden = NO;
        self.durationLabel.text = [SegmentDurationDateComponentsFormatter() stringFromTimeInterval:CMTimeGetSeconds(segment.srg_timeRange.duration)];
    }
    else {
        self.durationLabel.hidden = YES;
    }

    self.timestampLabel.text = [SegmentDurationDateComponentsFormatter() stringFromTimeInterval:CMTimeGetSeconds(segment.srg_timeRange.start)];

    self.alpha = segment.srg_isBlocked ? 0.5f : 1.f;
}

#pragma mark Overrides

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.progressView.progress = 0.f;
}

#pragma mark UI

- (void)updateAppearanceWithTime:(CMTime)time selectedSegment:(Segment *)selectedSegment
{
    CMTimeRange r = self.segment.srg_timeRange;
    float progress = (CMTimeGetSeconds(time) - CMTimeGetSeconds(r.start)) / (CMTimeGetSeconds(CMTimeAdd(r.start, r.duration)) - CMTimeGetSeconds(r.start));
    progress = fminf(1.f, fmaxf(0.f, progress));
    
    self.progressView.progress = progress;
    
    UIColor *selectionColor = [UIColor colorWithRed:128.f / 255.f green:0.f / 255.f blue:0.f / 255.f alpha:1.f];
    if (selectedSegment) {
        self.backgroundColor = (self.segment == selectedSegment) ? selectionColor : [UIColor blackColor];
    }
    else {
        self.backgroundColor = (progress != 0.f && progress != 1.f) ? selectionColor : [UIColor blackColor];
    }
}

@end
