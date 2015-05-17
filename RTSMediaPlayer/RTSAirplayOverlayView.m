//
//  Created by Frédéric Humbert-Droz on 17/05/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAirplayOverlayView.h"

@interface RTSAirplayOverlayView () <RTSAirplayOverlayViewDataSource>

@property (nonatomic, strong) MPVolumeView *volumeView;

@end

@implementation RTSAirplayOverlayView

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_volumeView = nil;
}

- (id) initWithFrame:(CGRect)frame
{
	if(!(self = [super initWithFrame:frame]))
		return nil;
	
	self.autoresizesSubviews = YES;
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.backgroundColor = [UIColor clearColor];
	
	[self setupView];

	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if(!(self = [super initWithCoder:aDecoder]))
		return nil;
	
	[self setupView];
	
	return self;
}

- (void) setupView
{
	self.contentMode = UIViewContentModeCenter;
	self.userInteractionEnabled = NO;
	self.hidden = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wirelessRouteActiveDidChange:) name:MPVolumeViewWirelessRouteActiveDidChangeNotification object:nil];
	
	self.volumeView = [[MPVolumeView alloc] init];
}

- (NSString*) activeAirplayOutputRouteName
{
	AVAudioSession* audioSession = [AVAudioSession sharedInstance];
	AVAudioSessionRouteDescription* currentRoute = audioSession.currentRoute;
	for (AVAudioSessionPortDescription* outputPort in currentRoute.outputs){
		if ([outputPort.portType isEqualToString:AVAudioSessionPortAirPlay])
			return outputPort.portName;
	}
	
	return nil;
}



#pragma mark - Notifications

- (void) wirelessRouteActiveDidChange:(NSNotification *)notification
{
	MPVolumeView* volumeView = (MPVolumeView*)notification.object;
	
	[self setNeedsDisplay];
	[self setHidden:!volumeView.isWirelessRouteActive];
}



#pragma mark - Drawings

- (void) drawRect:(CGRect)rect
{
	CGFloat width = 60.0f;
	CGFloat height = width * 10 / 16;
	
	CGFloat midX = CGRectGetMidX(rect);
	CGFloat midY = CGRectGetMidY(rect);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetAllowsAntialiasing(context, YES);
	
	CGContextSetLineWidth(context, 4.0);
	CGContextSetStrokeColorWithColor(context, self.tintColor.CGColor);
	
	CGRect rectangle = CGRectMake(midX-width,midY-height,width*2,height*2);
	CGContextAddRect(context, rectangle);
	CGContextStrokePath(context);
	
	CGFloat shapeSeparatorDelta = 5.0f;
	CGFloat quadCurveHeight = 20.0f;
	
	CGContextMoveToPoint(context, midX-width/2, midY+height+shapeSeparatorDelta);
	CGContextAddQuadCurveToPoint(context, midX, midY+height+quadCurveHeight, midX+width/2, midY+height+shapeSeparatorDelta);
	CGContextSetFillColorWithColor(context, self.tintColor.CGColor);
	CGContextFillPath(context);
	
	CGRect titleRect = CGRectMake(20, midY+height+quadCurveHeight, CGRectGetMaxX(rect)-40, 30.0f);
	[self drawTitleInRect:titleRect];
	
	CGRect subtitleRect = CGRectMake(20, CGRectGetMaxY(titleRect), CGRectGetMaxX(rect)-40, 30.0f);
	[self drawSubtitleInRect:subtitleRect];
}

- (void) drawTitleInRect:(CGRect)rect
{
	NSDictionary* attributes = [self airplayOverlayViewTitleAttributedDictionary:self];
	if ([self.dataSource respondsToSelector:@selector(airplayOverlayViewTitleAttributedDictionary:)])
		attributes = [self.dataSource airplayOverlayViewTitleAttributedDictionary:self];
	
	NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
	
	NSString *title = @"Airplay";
	[title drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:drawingContext];
}

- (void) drawSubtitleInRect:(CGRect)rect
{
	NSString *routeName = [self activeAirplayOutputRouteName];
	
	NSString *subtitle = [self airplayOverlayView:self subtitleForAirplayRouteName:routeName];
	if ([self.dataSource respondsToSelector:@selector(airplayOverlayView:subtitleForAirplayRouteName:)])
		subtitle = [self.dataSource airplayOverlayView:self subtitleForAirplayRouteName:routeName];
	
	if (subtitle.length > 0)
	{
		NSDictionary* attributes = [self airplayOverlayViewSubitleAttributedDictionary:self];
		if ([self.dataSource respondsToSelector:@selector(airplayOverlayViewSubitleAttributedDictionary:)])
			attributes = [self.dataSource airplayOverlayViewSubitleAttributedDictionary:self];
		
		NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
		drawingContext.minimumScaleFactor = 3/4;
		
		[subtitle drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:drawingContext];
	}
}



#pragma mark - RTSAirplayOverlayViewDataSource

- (NSDictionary *) airplayOverlayViewTitleAttributedDictionary:(RTSAirplayOverlayView *)airplayOverlayView
{
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	style.alignment = NSTextAlignmentCenter;
	
	return @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0f],
			  NSForegroundColorAttributeName : [UIColor whiteColor],
			  NSParagraphStyleAttributeName: style };
}

- (NSString *) airplayOverlayView:(RTSAirplayOverlayView *)airplayOverlayView subtitleForAirplayRouteName:(NSString *)routeName
{
	return [NSString stringWithFormat:@"Cette vidéo est en lecture sur «%@»", routeName];
}

- (NSDictionary *) airplayOverlayViewSubitleAttributedDictionary:(RTSAirplayOverlayView *)airplayOverlayView
{
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	style.alignment = NSTextAlignmentCenter;
	style.lineBreakMode = NSLineBreakByTruncatingTail;
	
	return @{ NSFontAttributeName : [UIFont systemFontOfSize:12.0f],
			  NSForegroundColorAttributeName : [UIColor darkGrayColor],
			  NSParagraphStyleAttributeName: style };
}

@end
