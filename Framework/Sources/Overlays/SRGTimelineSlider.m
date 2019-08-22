//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#if TARGET_OS_IOS

#import "SRGTimelineSlider.h"

#import "NSBundle+SRGMediaPlayer.h"

static void commonInit(SRGTimelineSlider *self);

@implementation SRGTimelineSlider

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Overrides

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CMTimeRange timeRange = self.mediaPlayerController.timeRange;
    if (CMTIMERANGE_IS_EMPTY(timeRange)) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect trackRect = [self trackRectForBounds:rect];
    CGFloat thumbStartXPos = CGRectGetMidX([self thumbRectForBounds:rect trackRect:trackRect value:self.minimumValue]);
    CGFloat thumbEndXPos = CGRectGetMidX([self thumbRectForBounds:rect trackRect:trackRect value:self.maximumValue]);
    
    for (id<SRGSegment> segment in self.mediaPlayerController.visibleSegments) {
        // Skip events not in the timeline
        if (CMTIME_COMPARE_INLINE(segment.srg_timeRange.start, <, timeRange.start)
                || CMTIME_COMPARE_INLINE(segment.srg_timeRange.start, >, CMTimeRangeGetEnd(timeRange))) {
            continue;
        }
        
        CGFloat tickXPos = thumbStartXPos + (CMTimeGetSeconds(segment.srg_timeRange.start) / CMTimeGetSeconds(timeRange.duration)) * (thumbEndXPos - thumbStartXPos);
        
        UIImage *iconImage = nil;
        if ([self.timelineSliderDelegate respondsToSelector:@selector(timelineSlider:iconImageForSegment:)]) {
            iconImage = [self.timelineSliderDelegate timelineSlider:self iconImageForSegment:segment];
        }
        
        if (iconImage) {
            CGFloat iconSide = 15.f;
            
            CGRect tickRect = CGRectMake(tickXPos - iconSide / 2.f,
                                         CGRectGetMidY(trackRect) - iconSide / 2.f,
                                         iconSide,
                                         iconSide);
            [iconImage drawInRect:tickRect];
        }
        else {
            static const CGFloat kTickWidth = 3.f;
            CGFloat tickHeight = 19.f;
            
            CGContextSetLineWidth(context, 1.f);
            CGContextSetStrokeColorWithColor(context, UIColor.blackColor.CGColor);
            CGContextSetFillColorWithColor(context, UIColor.whiteColor.CGColor);
            
            CGRect tickRect = CGRectMake(tickXPos - kTickWidth / 2.f,
                                         CGRectGetMidY(trackRect) - tickHeight / 2.f,
                                         kTickWidth,
                                         tickHeight);
            UIBezierPath *path = [UIBezierPath bezierPathWithRect:tickRect];
            [path fill];
            [path stroke];
        }
    }
}

#pragma mark Data

- (void)reloadData
{
    [self setNeedsDisplay];
}

#pragma mark Gestures

- (void)seekOnTap:(UIGestureRecognizer *)gestureRecognizer
{
    // Cannot tap on the thumb itself
    if (self.highlighted) {
        return;
    }
    
    CGFloat xPos = [gestureRecognizer locationInView:self].x;
    float value = self.minimumValue + (self.maximumValue - self.minimumValue) * xPos / CGRectGetWidth(self.bounds);
    CMTime time = CMTimeMakeWithSeconds(value, NSEC_PER_SEC);
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAroundTime:time] withCompletionHandler:nil];
}

@end

#pragma mark Static functions

static void commonInit(SRGTimelineSlider *self)
{
    NSString *thumbImagePath = [NSBundle.srg_mediaPlayerBundle pathForResource:@"thumb_timeline_slider" ofType:@"png"];
    UIImage *thumbImage = [UIImage imageWithContentsOfFile:thumbImagePath];
    [self setThumbImage:thumbImage forState:UIControlStateNormal];
    [self setThumbImage:thumbImage forState:UIControlStateHighlighted];
    
    // Add the ability to tap anywhere to seek at this specific location
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(seekOnTap:)];
    [self addGestureRecognizer:gestureRecognizer];
}

#endif
