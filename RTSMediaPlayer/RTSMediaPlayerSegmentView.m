//
//  Created by Samuel Défago on 22.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerSegmentView.h"

#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerSegmentViewImplementation.h"

static void commonInit(RTSMediaPlayerSegmentView *self);

@interface RTSMediaPlayerSegmentView ()

@property (nonatomic) RTSMediaPlayerSegmentViewImplementation *implementation;

@end

@implementation RTSMediaPlayerSegmentView

#pragma mark - Object lifecycle

- (instancetype) initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		commonInit(self);
	}
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder])
	{
		commonInit(self);
	}
	return self;
}

#pragma mark - Getters and setters

- (RTSMediaPlayerController *) mediaPlayerController
{
	return self.implementation.mediaPlayerController;
}

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	self.implementation.mediaPlayerController = mediaPlayerController;
}

- (id<RTSMediaPlayerSegmentDataSource>) dataSource
{
	return self.implementation.dataSource;
}

- (void) setDataSource:(id<RTSMediaPlayerSegmentDataSource>)dataSource
{
	self.implementation.dataSource = dataSource;
}

#pragma mark - Data

- (void) reloadSegments
{
	[self.implementation reloadSegments];
}

#pragma mark - RTSMediaPlayerSegmentView protocol

- (void) reloadWithSegments:(NSArray *)segments
{}

@end

static void commonInit(RTSMediaPlayerSegmentView *self)
{
	self.implementation = [[RTSMediaPlayerSegmentViewImplementation alloc] initWithView:self];
}
