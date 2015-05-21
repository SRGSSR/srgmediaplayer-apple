//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerSegmentOverlay.h"

static NSString * const RTSMediaPlayerSegmentCellIdentifier = @"RTSMediaPlayerSegmentCellIdentifier";

@interface RTSMediaPlayerSegmentOverlay ()

@property (nonatomic) NSArray *segments;
@property (nonatomic, weak) UITableView *tableView;

@end

static void commonInit(RTSMediaPlayerSegmentOverlay *self);

@implementation RTSMediaPlayerSegmentOverlay

// TODO: The table view implementation is temporary. The segment overlay should have a better default interface and
//       a way to override it

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

- (void)dealloc
{
	// Unregister KVO
	self.mediaPlayerController = nil;
}

#pragma mark - Getters and setters

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	if (_mediaPlayerController)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:RTSMediaPlayerPlaybackStateDidChangeNotification object:_mediaPlayerController];
	}
	
	_mediaPlayerController = mediaPlayerController;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateDidChange:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController];
}

#pragma mark - Overrides

- (void) willMoveToWindow:(UIWindow *)window
{
	[super willMoveToWindow:window];
	
	if (window)
	{
		[self loadSegments];
	}
}

#pragma mark - Data

- (void) loadSegments
{
	[self.dataSource mediaPlayerSegmentOverlay:self segmentsForIdentifier:self.mediaPlayerController.identifier completionHandler:^(NSArray *segments, NSError *error) {
        // FIXME: Must automatically retry if an error has been encountered
        
        self.segments = segments;
		[self.tableView reloadData];
	}];
}

#pragma mark - UITableViewDataSource protocol

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.segments.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [tableView dequeueReusableCellWithIdentifier:RTSMediaPlayerSegmentCellIdentifier forIndexPath:indexPath];
}

#pragma mar - UITableViewDelegate protocol

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	RTSMediaPlayerSegment *segment = self.segments[indexPath.row];
	cell.textLabel.text = segment.title;
}

#pragma mark - Notifications

- (void) playbackStateDidChange:(NSNotification *)notification
{
	NSAssert([notification.object isKindOfClass:[RTSMediaPlayerController class]], @"Expect a media player controller");
	
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	if (mediaPlayerController.playbackState == RTSMediaPlaybackStateReady)
	{
		[self loadSegments];
	}
}

@end

#pragma mark - Functions

static void commonInit(RTSMediaPlayerSegmentOverlay *self)
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:self.bounds];
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	tableView.dataSource = self;
	tableView.delegate = self;
	[self addSubview:tableView];
	self.tableView = tableView;
	
	[tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:RTSMediaPlayerSegmentCellIdentifier];
}