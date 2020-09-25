//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGAirPlayView.h"

#import "AVAudioSession+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "UIScreen+SRGMediaPlayer.h"
#import "SRGRouteDetector.h"
#import "SRGMediaPlayerLogger.h"

@import libextobjc;

@interface SRGAirPlayView ()

@property (nonatomic, getter=isFakedForInterfaceBuilder) BOOL fakedForInterfaceBuilder;

@end

static void commonInit(SRGAirPlayView *self);

@implementation SRGAirPlayView

#pragma mark Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
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
        
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UIScreenDidConnectNotification
                                                    object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self
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
        
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.player.externalPlaybackActive) options:0 block:observationBlock];
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.player.usesExternalPlaybackWhileExternalScreenIsActive) options:0 block:observationBlock];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_airPlayView_screenDidConnect:)
                                                   name:UIScreenDidConnectNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(srg_airPlayView_screenDidDisconnect:)
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
    NSDictionary<NSString *, id> *attributes = [self airPlayViewTitleAttributedDictionary:self];
    if ([self.delegate respondsToSelector:@selector(airPlayViewTitleAttributedDictionary:)]) {
        attributes = [self.delegate airPlayViewTitleAttributedDictionary:self];
    }
    
    NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
    
    NSString *title = SRGMediaPlayerNonLocalizedString(@"AirPlay");
    [title drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:drawingContext];
}

- (void)drawSubtitleInRect:(CGRect)rect
{
    NSString *subtitle = [self airPlayViewSubtitle:self];
    if ([self.delegate respondsToSelector:@selector(airPlayViewSubtitle:)]) {
        subtitle = [self.delegate airPlayViewSubtitle:self];
    }
    
    if (subtitle.length > 0) {
        NSDictionary<NSString *, id> *attributes = [self airPlayViewSubtitleAttributedDictionary:self];
        if ([self.delegate respondsToSelector:@selector(airPlayViewSubtitleAttributedDictionary:)]) {
            attributes = [self.delegate airPlayViewSubtitleAttributedDictionary:self];
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
        if (mediaPlayerController.externalNonMirroredPlaybackActive) {
            self.hidden = ! AVAudioSession.srg_isAirPlayActive;
        }
        else {
            self.hidden = YES;
        }
    }
    else {
        self.hidden = ! self.fakedForInterfaceBuilder && ! AVAudioSession.srg_isAirPlayActive;
    }
    
    if (wasHidden && ! self.hidden && [self.delegate respondsToSelector:@selector(airPlayView:didShowWithAirPlayRouteName:)]) {
        [self.delegate airPlayView:self didShowWithAirPlayRouteName:AVAudioSession.srg_activeAirPlayRouteName];
    }
    else if (! wasHidden && self.hidden && [self.delegate respondsToSelector:@selector(airPlayViewDidHide:)]) {
        [self.delegate airPlayViewDidHide:self];
    }
}

#pragma mark SRGAirPlayViewDataSource protocol

- (NSDictionary<NSString *, id> *)airPlayViewTitleAttributedDictionary:(SRGAirPlayView *)airPlayView
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    
    return @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:14.f],
              NSForegroundColorAttributeName: self.tintColor,
              NSParagraphStyleAttributeName: style };
}

- (NSString *)airPlayViewSubtitle:(SRGAirPlayView *)airPlayView
{
    return SRGAirPlayRouteDescription();
}

- (NSDictionary<NSString *, id> *)airPlayViewSubtitleAttributedDictionary:(SRGAirPlayView *)airPlayView
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    
    return @{ NSFontAttributeName: [UIFont systemFontOfSize:12.f],
              NSForegroundColorAttributeName: self.tintColor,
              NSParagraphStyleAttributeName: style };
}

#pragma mark Notifications

- (void)srg_airPlayView_screenDidConnect:(NSNotification *)notification
{
    [self updateAppearance];
}

- (void)srg_airPlayView_screenDidDisconnect:(NSNotification *)notification
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

static void commonInit(SRGAirPlayView *self)
{
    self.contentMode = UIViewContentModeRedraw;
    self.userInteractionEnabled = NO;
    self.hidden = YES;
}

NSString * SRGAirPlayRouteDescription(void)
{
    NSString *routeName = [AVAudioSession srg_activeAirPlayRouteName];
    if (routeName) {
        return [NSString stringWithFormat:SRGMediaPlayerLocalizedString(@"Playback on «%@»", @"AirPlay description on which device the media is played."), routeName];
    }
    else {
        return nil;
    }
}

#endif
