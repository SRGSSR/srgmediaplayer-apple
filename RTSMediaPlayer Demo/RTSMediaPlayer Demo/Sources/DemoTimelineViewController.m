//
//  Created by Samuel Défago on 29.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "DemoTimelineViewController.h"

#import "EventCollectionViewCell.h"

static NSString * const DemoTimeLineEventIdentifier = @"265862";

@interface DemoTimelineViewController ()

@property (nonatomic) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic) NSArray *timelineEvents;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet RTSTimelineView *timelineView;

@end

@implementation DemoTimelineViewController

#pragma mark - Object lifecycle

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	_mediaPlayerController = mediaPlayerController;
	
	// Refresh every 30 seconds
	[mediaPlayerController addPlaybackTimeObserverForInterval:CMTimeMakeWithSeconds(30., 1.) queue:NULL usingBlock:^(CMTime time) {
		[self refreshTimeline];
	}];
}

#pragma mark - View lifecycle

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	NSString *className = NSStringFromClass([EventCollectionViewCell class]);
	UINib *cellNib = [UINib nibWithNibName:className bundle:nil];
	[self.timelineView registerNib:cellNib forCellWithReuseIdentifier:className];
	
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
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if ([self isMovingFromParentViewController] || [self isBeingDismissed])
	{
		[self.mediaPlayerController reset];
	}
}

#pragma mark - Data

- (void) retrieveStartDateWithCompletionBlock:(void (^)(NSDate *startDate, NSError *error))completionBlock
{
	NSString *URLString = [NSString stringWithFormat:@"http://test.event.api.swisstxt.ch/v1/events/srf/byEventItemId/%@", DemoTimeLineEventIdentifier];
	[[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:URLString] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error)
			{
				completionBlock ? completionBlock(nil, error) : nil;
				return;
			}
			
			id responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
			if (!responseObject || ![responseObject isKindOfClass:[NSArray class]])
			{
				NSError *parseError = [NSError errorWithDomain:NSURLErrorDomain
														  code:NSURLErrorCannotParseResponse
													  userInfo:@{ NSLocalizedDescriptionKey : @"Invalid response format" }];
				completionBlock ? completionBlock(nil, parseError) : nil;
				return;
			}
			
			// ISO 8601 date formatting
			static NSDateFormatter *s_dateFormatter;
			static dispatch_once_t s_onceToken;
			dispatch_once(&s_onceToken, ^{
				s_dateFormatter = [[NSDateFormatter alloc] init];
				[s_dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
			});
			
			NSDictionary *eventDictionary = [responseObject firstObject];
			NSDate *startDate = [s_dateFormatter dateFromString:eventDictionary[@"startDate"]];
			if (!startDate)
			{
				NSError *dateError = [NSError errorWithDomain:NSURLErrorDomain
														 code:NSURLErrorCannotParseResponse
													 userInfo:@{ NSLocalizedDescriptionKey : @"Missing date in response, or bad format" }];
				completionBlock ? completionBlock(nil, dateError) : nil;
				return;
			}
			
			completionBlock ? completionBlock(startDate, nil) : nil;
		});
	}] resume];
}

- (void) retrieveTimelineEventsForStartDate:(NSDate *)startDate withCompletionBlock:(void (^)(NSArray *timelineEvents, NSError *error))completionBlock
{
	NSAssert(startDate, @"A start date is mandatory");
	
	NSString *URLString = [NSString stringWithFormat:@"http://test.event.api.swisstxt.ch:80/v1/highlights/srf/byEventItemId/%@", DemoTimeLineEventIdentifier];
	[[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:URLString] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error)
			{
				completionBlock ? completionBlock(nil, error) : nil;
				return;
			}
			
			id responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
			if (!responseObject || ![responseObject isKindOfClass:[NSArray class]])
			{
				NSError *parseError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotParseResponse userInfo:nil];
				completionBlock ? completionBlock(nil, parseError) : nil;
				return;
			}
			
			NSMutableArray *timelineEvents = [NSMutableArray array];
			for (NSDictionary *highlight in responseObject)
			{
				// Note that the start date available from this JSON (streamStartDate) is not reliable and is retrieve using
				// another request
				NSDate *date = [NSDate dateWithTimeIntervalSince1970:[highlight[@"timestamp"] doubleValue]];
				CMTime time = CMTimeMake([date timeIntervalSinceDate:startDate], 1.);
				RTSTimelineEvent *timelineEvent = [[RTSTimelineEvent alloc] initWithTime:time];
				timelineEvent.title = highlight[@"title"];
				[timelineEvents addObject:timelineEvent];
			}
			
			completionBlock ? completionBlock([NSArray arrayWithArray:timelineEvents], nil) : nil;
		});
	}] resume];
}

- (void) refreshTimeline
{
	[self retrieveStartDateWithCompletionBlock:^(NSDate *startDate, NSError *error) {
		[self retrieveTimelineEventsForStartDate:startDate withCompletionBlock:^(NSArray *timelineEvents, NSError *error) {
			if (error)
			{
				return;
			}
			
			self.timelineView.events = timelineEvents;
		}];
	}];
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

- (UICollectionViewCell *) timelineView:(RTSTimelineView *)timelineView cellForEvent:(RTSTimelineEvent *)event
{
	EventCollectionViewCell *eventCell = [timelineView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([EventCollectionViewCell class]) forEvent:event];
	eventCell.event = event;
	return eventCell;
}

#pragma mark - RTSTimelineViewDelegate protocol

- (CGFloat) itemWidthForTimelineView:(RTSTimelineView *)timelineView
{
	return 162.f;
}

- (CGFloat) itemSpacingForTimelineView:(RTSTimelineView *)timelineView
{
	return 4.f;
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
