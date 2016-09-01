//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAirplayView.h"

#import "NSBundle+SRGMediaPlayer.h"

@interface SRGAirplayView ()

@property (nonatomic) MPVolumeView *volumeView;

@end

static const CGFloat RTSAirplayViewDefaultFillFactor = 0.6f;

static void commonInit(SRGAirplayView *self);

@implementation SRGAirplayView

#pragma mark Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.autoresizesSubviews = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor clearColor];
        commonInit(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

- (void)setFillFactor:(CGFloat)fillFactor
{
    if (fillFactor <= 0.f) {
        _fillFactor = RTSAirplayViewDefaultFillFactor;
    }
    else if (fillFactor > 1.f) {
        _fillFactor = 1.f;
    }
    else {
        _fillFactor = fillFactor;
    }

    [self setNeedsDisplay];
}

- (NSString *)activeAirplayOutputRouteName
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = audioSession.currentRoute;
    
    for (AVAudioSessionPortDescription *outputPort in currentRoute.outputs) {
        if ([outputPort.portType isEqualToString:AVAudioSessionPortAirPlay]) {
            return outputPort.portName;
        }
    }
    
    return RTSMediaPlayerLocalizedString(@"External device", nil);
}

#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{
    CGFloat width, height;
    CGFloat stringRectHeight = 30.f;
    CGFloat stringRectMargin = 5.f;
    CGFloat lineWidth = 4.f;
    CGFloat shapeSeparatorDelta = 5.f;
    CGFloat quadCurveHeight = 20.f;

    CGFloat maxWidth = CGRectGetWidth(self.bounds) * self.fillFactor - 2.f * lineWidth;
    CGFloat maxHeight = CGRectGetHeight(self.bounds) * self.fillFactor - stringRectHeight - quadCurveHeight - shapeSeparatorDelta - 10.f;
    CGFloat aspectRatio = 16.f / 10.f;

    if (maxWidth < maxHeight * aspectRatio) {
        width = maxWidth;
        height = width / aspectRatio;
    }
    else {
        height = maxHeight;
        width = height * aspectRatio;
    }

    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetAllowsAntialiasing(context, YES);

    CGContextSetLineWidth(context, 4.f);
    CGContextSetStrokeColorWithColor(context, self.tintColor.CGColor);

    CGRect rectangle = CGRectMake(midX - width / 2.f, midY - height / 2.f, width, height);
    CGContextAddRect(context, rectangle);
    CGContextStrokePath(context);

    CGContextMoveToPoint(context, midX - width / 4.f, midY + height / 2.f + shapeSeparatorDelta);
    CGContextAddQuadCurveToPoint(context, midX, midY + height / 2.f + quadCurveHeight, midX + width / 4.f, midY + height / 2.f + shapeSeparatorDelta);
    CGContextSetFillColorWithColor(context, self.tintColor.CGColor);
    CGContextFillPath(context);

    CGRect titleRect = CGRectInset(rectangle, 8.f, 10.f);
    [self drawTitleInRect:titleRect];

    CGRect subtitleRect = CGRectMake(stringRectMargin, midY + height / 2.f + quadCurveHeight - 5.f, CGRectGetMaxX(rect) - 2.f * stringRectMargin, stringRectHeight);
    [self drawSubtitleInRect:subtitleRect];
}

- (void)drawTitleInRect:(CGRect)rect
{
    NSDictionary<NSString *, id> *attributes = [self airplayViewTitleAttributedDictionary:self];
    if ([self.dataSource respondsToSelector:@selector(airplayViewTitleAttributedDictionary:)]) {
        attributes = [self.dataSource airplayViewTitleAttributedDictionary:self];
    }

    NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];

    NSString *title = @"Airplay";
    [title drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:drawingContext];
}

- (void)drawSubtitleInRect:(CGRect)rect
{
    NSString *routeName = [self activeAirplayOutputRouteName];

    NSString *subtitle = [self airplayView:self subtitleForAirplayRouteName:routeName];
    if ([self.dataSource respondsToSelector:@selector(airplayView:subtitleForAirplayRouteName:)]) {
        subtitle = [self.dataSource airplayView:self subtitleForAirplayRouteName:routeName];
    }

    if (subtitle.length > 0) {
        NSDictionary<NSString *, id> *attributes = [self airplayViewSubtitleAttributedDictionary:self];
        if ([self.dataSource respondsToSelector:@selector(airplayViewSubtitleAttributedDictionary:)]) {
            attributes = [self.dataSource airplayViewSubtitleAttributedDictionary:self];
        }

        NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
        drawingContext.minimumScaleFactor = 3.f / 4.f;

        [subtitle drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:drawingContext];
    }
}

#pragma mark RTSAirplayViewDataSource protocol

- (NSDictionary<NSString *, id> *)airplayViewTitleAttributedDictionary:(SRGAirplayView *)airplayView
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;

    return @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:14.f],
              NSForegroundColorAttributeName: self.tintColor,
              NSParagraphStyleAttributeName: style };
}

- (NSString *)airplayView:(SRGAirplayView *)airplayView subtitleForAirplayRouteName:(NSString *)routeName
{
    return [NSString stringWithFormat:RTSMediaPlayerLocalizedString(@"This media is playing on «%@»", nil), routeName];
}

- (NSDictionary<NSString *, id> *)airplayViewSubtitleAttributedDictionary:(SRGAirplayView *)airplayView
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    style.lineBreakMode = NSLineBreakByTruncatingTail;

    return @{ NSFontAttributeName: [UIFont systemFontOfSize:12.f],
              NSForegroundColorAttributeName: self.tintColor,
              NSParagraphStyleAttributeName: style };
}

#pragma mark Notifications

- (void)wirelessRouteActiveDidChange:(NSNotification *)notification
{
    [self setNeedsDisplay];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = audioSession.currentRoute;
    
    BOOL hidden = YES;
    for (AVAudioSessionPortDescription *outputPort in currentRoute.outputs) {
        if ([outputPort.portType isEqualToString:AVAudioSessionPortAirPlay]) {
            hidden = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(airplayViewCouldBeDisplayed:)]) {
                if (! [self.delegate airplayViewCouldBeDisplayed:self]) {
                    hidden = YES;
                }
            }
            break;
        }
    }
    
    [self setHidden:hidden];
}

@end

#pragma mark Static functions

static void commonInit(SRGAirplayView *self)
{
    self.contentMode = UIViewContentModeRedraw;
    self.userInteractionEnabled = NO;
    self.hidden = YES;
    self.fillFactor = RTSAirplayViewDefaultFillFactor;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wirelessRouteActiveDidChange:)
                                                 name:MPVolumeViewWirelessRouteActiveDidChangeNotification
                                               object:nil];
    
    self.volumeView = [[MPVolumeView alloc] init];
}