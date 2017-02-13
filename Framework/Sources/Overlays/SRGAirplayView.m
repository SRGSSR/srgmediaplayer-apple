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
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@interface SRGAirplayView ()

@property (nonatomic) MPVolumeView *volumeView;
@property (nonatomic, getter=isFakedForInterfaceBuilder) BOOL fakedForInterfaceBuilder;

@end

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
    self.mediaPlayerController = nil;       // Unregister everything
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.player.externalPlaybackActive)];
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive)];
        
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
        @weakify(self)
        void (^observationBlock)(MAKVONotification *) = ^(MAKVONotification *notification) {
            @strongify(self)
            [self updateAppearance];
        };
        
        [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.player.externalPlaybackActive) options:0 block:observationBlock];
        [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) options:0 block:observationBlock];
        
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

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self updateAppearance];
    }
}

#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{
    // Do not display the default overlay if a custom view is used (i.e. containing subviews)
    if (self.subviews.count != 0) {
        return;
    }
    
    CGFloat width, height;
    CGFloat stringRectHeight = 30.f;
    CGFloat stringRectMargin = 5.f;
    CGFloat lineWidth = 4.f;
    CGFloat shapeSeparatorDelta = 5.f;
    CGFloat quadCurveHeight = 20.f;

    static CGFloat kFillFactor = 0.6f;
    CGFloat maxWidth = CGRectGetWidth(self.bounds) * kFillFactor - 2.f * lineWidth;
    CGFloat maxHeight = CGRectGetHeight(self.bounds) * kFillFactor - stringRectHeight - quadCurveHeight - shapeSeparatorDelta - 10.f;
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
    NSString *subtitle = [self airplayViewSubtitle:self];
    if ([self.delegate respondsToSelector:@selector(airplayViewSubtitle:)]) {
        subtitle = [self.delegate airplayViewSubtitle:self];
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
    // Do not update before the view is actually visible, so that show / hide delegate methods are correclty called 
    if (! self.window) {
        return;
    }
    
    [self setNeedsDisplay];
    
    BOOL wasHidden = self.hidden;
    
    if (mediaPlayerController) {
        // True Airplay active. Use Airplay availability status
        if (mediaPlayerController.externalNonMirroredPlaybackActive) {
            self.hidden = ! [AVAudioSession srg_isAirplayActive];
        }
        else {
            self.hidden = YES;
        }
    }
    else {
        self.hidden = ! self.fakedForInterfaceBuilder && ! [AVAudioSession srg_isAirplayActive];
    }
    
    if (wasHidden && ! self.hidden && [self.delegate respondsToSelector:@selector(airplayView:didShowWithAirplayRouteName:)]) {
        [self.delegate airplayView:self didShowWithAirplayRouteName:[AVAudioSession srg_activeAirplayRouteName]];
    }
    else if (! wasHidden && self.hidden && [self.delegate respondsToSelector:@selector(airplayViewDidHide:)]) {
        [self.delegate airplayViewDidHide:self];
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

- (NSString *)airplayViewSubtitle:(SRGAirplayView *)airplayView
{
    return SRGAirplayRouteDescription();
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

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    
    self.fakedForInterfaceBuilder = YES;
    [self updateAppearance];
}

@end

#pragma mark Functions

static void commonInit(SRGAirplayView *self)
{
    self.contentMode = UIViewContentModeRedraw;
    self.userInteractionEnabled = NO;
    self.hidden = YES;
    self.volumeView = [[MPVolumeView alloc] init];
}

NSString * SRGAirplayRouteDescription(void)
{
    NSString *routeName = [AVAudioSession srg_activeAirplayRouteName];
    if (routeName) {
        return [NSString stringWithFormat:SRGMediaPlayerLocalizedString(@"This media is playing on «%@»", nil), routeName];
    }
    else {
        return nil;
    }
}
