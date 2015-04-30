//
//  Created by Samuel Défago on 29.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "DemoTimelineViewController.h"

static NSString * const DemoTimeLineEventIdentifier = @"265862";
static const NSTimeInterval DemoTimeLineRefreshInterval = 30.;

@interface DemoTimelineViewController ()

@property (nonatomic) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic) NSArray *timelineEvents;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet RTSTimelineView *timelineView;

@property (nonatomic) NSTimer *timelineRefreshTimer;

@end

@implementation DemoTimelineViewController

#pragma mark - Object lifecycle

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (void) setTimelineRefreshTimer:(NSTimer *)timelineRefreshTimer
{
	if (_timelineRefreshTimer)
	{
		[_timelineRefreshTimer invalidate];
	}
	
	_timelineRefreshTimer = timelineRefreshTimer;
}

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	_mediaPlayerController = mediaPlayerController;
	
	// Refresh every 30 seconds
	[mediaPlayerController registerPlaybackBlock:^(CMTime time) {
		[self refreshTimeline];
	} forInterval:CMTimeMakeWithSeconds(30., 1.)];
}

#pragma mark - View lifecycle

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mediaPlayerDidShowControlOverlays:)
												 name:RTSMediaPlayerDidShowControlOverlaysNotification
											   object:self.mediaPlayerController];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mediaPlayerDidHideControlOverlays:)
												 name:RTSMediaPlayerDidHideControlOverlaysNotification
											   object:self.mediaPlayerController];
	
	[self.mediaPlayerController attachPlayerToView:self.videoView];
}

- (void) viewWillAppear:(BOOL)animated
{
	if ([self isMovingToParentViewController] || [self isBeingPresented])
	{
		[self.mediaPlayerController play];
	}
	
	self.timelineRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:DemoTimeLineRefreshInterval
																 target:self
															   selector:@selector(refreshTimeline:)
															   userInfo:nil
																repeats:YES];
	[self.timelineRefreshTimer fire];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if ([self isMovingFromParentViewController] || [self isBeingDismissed])
	{
		[self.mediaPlayerController reset];
	}
	
	self.timelineRefreshTimer = nil;
}

#pragma mark - Data

- (void) refreshTimeline
{
	NSString *URLString = [NSString stringWithFormat:@"http://test.event.api.swisstxt.ch:80/v1/highlights/srf/byEventItemId/%@", DemoTimeLineEventIdentifier];
	[[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:URLString] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error)
			{
				return;
			}
			
			id responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
			if (!responseObject || ![responseObject isKindOfClass:[NSArray class]])
			{
				return;
			}
			
			NSMutableArray *timelineEvents = [NSMutableArray array];
			for (NSDictionary *highlight in responseObject)
			{
				NSDate *streamStartDate = [NSDate dateWithTimeIntervalSince1970:[highlight[@"streamStartTime"] doubleValue]];
				NSDate *highlightDate = [NSDate dateWithTimeIntervalSince1970:[highlight[@"timestamp"] doubleValue]];
				
				CMTime time = CMTimeMake([highlightDate timeIntervalSinceDate:streamStartDate], 1.);
				RTSTimelineEvent *timelineEvent = [[RTSTimelineEvent alloc] initWithTime:time];
				timelineEvent.title = highlight[@"title"];
				[timelineEvents addObject:timelineEvent];
			}
			self.timelineEvents = [NSArray arrayWithArray:timelineEvents];
			
			[self.timelineView reloadData];
		});
	}] resume];
}

#pragma mark - RTSMediaPlayerControllerDataSource protocol

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	NSString *URLString = [NSString stringWithFormat:@"http://test.event.api.swisstxt.ch:80/v1/stream/srf/byEventItemIdAndType/%@/hls", DemoTimeLineEventIdentifier];
	[[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:URLString] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error)
			{
				completionHandler(nil, error);
				return;
			}
			
			NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			if (! responseString)
			{
				NSError *responseError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
				completionHandler(nil, responseError);
			}
			responseString = [responseString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
			
			NSURL *URL = [NSURL URLWithString:responseString];
			completionHandler(URL, nil);
		});
	}] resume];
}

#pragma mark - RTSTimelineViewDataSource protocol

- (NSInteger) numberOfEventsInTimelineView:(RTSTimelineView *)timelineView
{
	return self.timelineEvents.count;
}

- (RTSTimelineEvent *) timelineView:(RTSTimelineView *)timelineView eventAtIndex:(NSInteger)index
{
	return self.timelineEvents[index];
}

#pragma mark - Actions

- (IBAction) dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notifications

- (void) mediaPlayerDidShowControlOverlays:(NSNotification *)notification
{
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void) mediaPlayerDidHideControlOverlays:(NSNotification *)notificaiton
{
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
}

#pragma mark - Timers

- (void) refreshTimeline:(NSTimer *)timer
{
	[self refreshTimeline];
}

@end
