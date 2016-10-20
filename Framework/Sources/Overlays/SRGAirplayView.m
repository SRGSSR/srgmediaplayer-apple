//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAirplayView.h"

#import "AVAudioSession+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "UIScreen+SRGMediaPlayer.h"
#import "SRGMediaPlayerLogger.h"

#import <libextobjc/libextobjc.h>

static void *s_kvoContext = &s_kvoContext;

@interface SRGAirplayView ()

@property (nonatomic) MPVolumeView *volumeView;
@property (nonatomic, getter=isFakedForInterfaceBuilder) BOOL fakedForInterfaceBuilder;

@end

static const CGFloat SRGAirplayViewDefaultFillFactor = 0.6f;

static void commonInit(SRGAirplayView *self);

@implementation SRGAirplayView

#pragma mark Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
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
    self.mediaPlayerController = nil;       // Unregister KVO
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [_mediaPlayerController removeObserver:self forKeyPath:@keypath(_mediaPlayerController.player.externalPlaybackActive) context:s_kvoContext];
        [_mediaPlayerController removeObserver:self forKeyPath:@keypath(_mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) context:s_kvoContext];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPVolumeViewWirelessRouteActiveDidChangeNotification
                                                      object:self.volumeView];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIScreenDidConnectNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIScreenDidDisconnectNotification
                                                      object:nil];
    }
    
    _mediaPlayerController = mediaPlayerController;
    [self updateAppearanceForMediaPlayerController:mediaPlayerController];
    
    if (mediaPlayerController) {
        [mediaPlayerController addObserver:self forKeyPath:@keypath(mediaPlayerController.player.externalPlaybackActive) options:0 context:s_kvoContext];
        [mediaPlayerController addObserver:self forKeyPath:@keypath(mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) options:0 context:s_kvoContext];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_airplayView_wirelessRouteActiveDidChange:)
                                                     name:MPVolumeViewWirelessRouteActiveDidChangeNotification
                                                   object:self.volumeView];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_airplayView_screenDidConnect:)
                                                     name:UIScreenDidConnectNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_airplayView_screenDidDisconnect:)
                                                     name:UIScreenDidDisconnectNotification
                                                   object:nil];
    }
}

- (void)setFillFactor:(CGFloat)fillFactor
{
    if (fillFactor <= 0.f) {
        SRGMediaPlayerLogWarning(@"AirplayView", @"Fill factor cannot be negative. Fixed to 0");
        _fillFactor = SRGAirplayViewDefaultFillFactor;
    }
    else if (fillFactor > 1.f) {
        SRGMediaPlayerLogWarning(@"AirplayView", @"Fill factor cannot be larger than 1. Fixed to 1");
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
    
    return SRGMediaPlayerLocalizedString(@"External device", nil);
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
    if ([self.delegate respondsToSelector:@selector(airplayViewTitleAttributedDictionary:)]) {
        attributes = [self.delegate airplayViewTitleAttributedDictionary:self];
    }

    NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];

    NSString *title = @"Airplay";
    [title drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:drawingContext];
}

- (void)drawSubtitleInRect:(CGRect)rect
{
    NSString *routeName = [self activeAirplayOutputRouteName];

    NSString *subtitle = [self airplayView:self subtitleForAirplayRouteName:routeName];
    if ([self.delegate respondsToSelector:@selector(airplayView:subtitleForAirplayRouteName:)]) {
        subtitle = [self.delegate airplayView:self subtitleForAirplayRouteName:routeName];
    }

    if (subtitle.length > 0) {
        NSDictionary<NSString *, id> *attributes = [self airplayViewSubtitleAttributedDictionary:self];
        if ([self.delegate respondsToSelector:@selector(airplayViewSubtitleAttributedDictionary:)]) {
            attributes = [self.delegate airplayViewSubtitleAttributedDictionary:self];
        }

        NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
        drawingContext.minimumScaleFactor = 3.f / 4.f;

        [subtitle drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:drawingContext];
    }
}

#pragma mark UI

- (void)updateAppearance
{
    [self updateAppearanceForMediaPlayerController:self.mediaPlayerController];
}

- (void)updateAppearanceForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    [self setNeedsDisplay];
    
    if (mediaPlayerController) {
        // Device mirrored, and playback not sent to the external display. Always hide the overlay (true mirroring: never
        // show Airplay controls on the device screen, and thus on the external display)
        if ([UIScreen srg_isMirroring] && ! mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) {
            self.hidden = YES;
        }
        // Otherwise use Airplay status
        else {
            self.hidden = ! [AVAudioSession srg_isAirplayActive];
        }
    }
    else {
        self.hidden = ! self.fakedForInterfaceBuilder && ! [AVAudioSession srg_isAirplayActive];
    }
}

#pragma mark SRGAirplayViewDataSource protocol

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
    return [NSString stringWithFormat:SRGMediaPlayerLocalizedString(@"This media is playing on «%@»", nil), routeName];
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

- (void)srg_airplayView_wirelessRouteActiveDidChange:(NSNotification *)notification
{
    [self updateAppearance];
}

- (void)srg_airplayView_screenDidConnect:(NSNotification *)notification
{
    [self updateAppearance];
}

- (void)srg_airplayView_screenDidDisconnect:(NSNotification *)notification
{
    [self updateAppearance];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == s_kvoContext) {
        SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerController;
        if ([keyPath isEqualToString:@keypath(mediaPlayerController.player.externalPlaybackActive)]
                || [keyPath isEqualToString:@keypath(mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive)]) {
            [self updateAppearance];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    
    self.fakedForInterfaceBuilder = YES;
    [self updateAppearance];
}

@end

#pragma mark Static functions

static void commonInit(SRGAirplayView *self)
{
    self.contentMode = UIViewContentModeRedraw;
    self.userInteractionEnabled = NO;
    self.hidden = YES;
    self.fillFactor = SRGAirplayViewDefaultFillFactor;
    self.volumeView = [[MPVolumeView alloc] init];
}
