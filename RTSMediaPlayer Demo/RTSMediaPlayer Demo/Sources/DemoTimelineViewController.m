//
//  Created by Samuel Défago on 29.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "DemoTimelineViewController.h"

#import "EventCollectionViewCell.h"

@interface DemoTimelineViewController ()

@property (nonatomic) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic) NSArray *timelineEvents;

@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet RTSTimelineView *timelineView;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *timelineActivityIndicatorView;

@end

@implementation DemoTimelineViewController

#pragma mark - Object lifecycle

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getters and setters

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	if (_mediaPlayerController)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:RTSMediaPlayerPlaybackDidFailNotification
													  object:_mediaPlayerController];
	}
	
	_mediaPlayerController = mediaPlayerController;
	
	if (mediaPlayerController)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playbackDidFail:)
													 name:RTSMediaPlayerPlaybackDidFailNotification
												   object:mediaPlayerController];
		
		// Refresh every 30 seconds
		[mediaPlayerController addPlaybackTimeObserverForInterval:CMTimeMakeWithSeconds(30., 1.) queue:NULL usingBlock:^(CMTime time) {
			[self refreshTimeline];
		}];
	}
}

- (void) setVideoIdentifier:(NSString *)videoIdentifier
{
	_videoIdentifier = videoIdentifier;
	
	[self.mediaPlayerController playIdentifier:videoIdentifier];
}

#pragma mark - View lifecycle

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.timelineView.itemWidth = 162.f;
	self.timelineView.itemSpacing = 0.f;
	
	self.timelineActivityIndicatorView.hidden = YES;
	
	NSString *className = NSStringFromClass([EventCollectionViewCell class]);
	UINib *cellNib = [UINib nibWithNibName:className bundle:nil];
	[self.timelineView registerNib:cellNib forCellWithReuseIdentifier:className];
	
	[self.mediaPlayerController attachPlayerToView:self.videoView];
}

- (void) viewWillAppear:(BOOL)animated
{
	if ([self isMovingToParentViewController] || [self isBeingPresented])
	{
		[self.mediaPlayerController playIdentifier:self.videoIdentifier];
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
	}
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if ([self isMovingFromParentViewController] || [self isBeingDismissed])
	{
		[self.mediaPlayerController reset];
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
	}
}

#pragma mark - Data

- (void) retrieveEventsWithCompletionBlock:(void (^)(NSArray *events, NSError *error))completionBlock
{
	NSString *URLString = [NSString stringWithFormat:@"http://test.event.api.swisstxt.ch:80/v1/highlights/srf/byEventItemId/%@", self.videoIdentifier];
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
			
			NSMutableArray *events = [NSMutableArray array];
			for (NSDictionary *highlight in responseObject)
			{
				// Note that the start date available from this JSON (streamStartDate) is not reliable and is retrieve using
				// another request
				NSDate *date = [NSDate dateWithTimeIntervalSince1970:[highlight[@"timestamp"] doubleValue]];
				NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[highlight[@"streamStartTime"] doubleValue]];
				CMTime time = CMTimeMake([date timeIntervalSinceDate:startDate], 1.);
				
				Event *event = [[Event alloc] initWithTime:time title:highlight[@"title"] identifier:highlight[@"id"] date:date];
				if (event) {
					[events addObject:event];
				}
			}
			
			completionBlock ? completionBlock([NSArray arrayWithArray:events], nil) : nil;
		});
	}] resume];
}

- (void) refreshTimeline
{
	self.timelineActivityIndicatorView.hidden = NO;
	[self.timelineActivityIndicatorView startAnimating];
	
	[self retrieveEventsWithCompletionBlock:^(NSArray *events, NSError *error) {
		self.timelineActivityIndicatorView.hidden = YES;
		[self.timelineActivityIndicatorView stopAnimating];
		
		if (error)
		{
			return;
		}
		
		self.timelineView.events = events;
	}];
}

#pragma mark - RTSMediaPlayerControllerDataSource protocol

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	NSString *URLString = [NSString stringWithFormat:@"http://test.event.api.swisstxt.ch:80/v1/stream/srf/byEventItemIdAndType/%@/hls", identifier];
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

#pragma mark - RTSTimelideSliderDataSource protocol

- (UIImage *) timelineSlider:(RTSTimelineSlider *)slider iconImageForEvent:(RTSTimelineEvent *)event
{
	return ((Event *)event).iconImage;
}

#pragma mark - RTSTimelineViewDataSource protocol

- (UICollectionViewCell *) timelineView:(RTSTimelineView *)timelineView cellForEvent:(RTSTimelineEvent *)event
{
	EventCollectionViewCell *eventCell = [timelineView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([EventCollectionViewCell class]) forEvent:event];
	eventCell.event = (Event *)event;
	return eventCell;
}

#pragma mark - Actions

- (IBAction) dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) seekBackward:(id)sender
{
	CMTime currentTime = self.mediaPlayerController.player.currentTime;
	CMTime increment = CMTimeMakeWithSeconds(30., 1.);
	
	[self.mediaPlayerController.player seekToTime:CMTimeSubtract(currentTime, increment)];
}

- (IBAction) seekForward:(id)sender
{
	CMTime currentTime = self.mediaPlayerController.player.currentTime;
	CMTime increment = CMTimeMakeWithSeconds(30., 1.);
	
	[self.mediaPlayerController.player seekToTime:CMTimeAdd(currentTime, increment)];
}

#pragma mark - Notifications

- (void) playbackDidFail:(NSNotification *)notifications
{
	[self dismissViewControllerAnimated:YES completion:nil];
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
														message:@"The video could not be played"
													   delegate:nil
											  cancelButtonTitle:@"Dismiss"
											  otherButtonTitles:nil];
	[alertView show];
}

#pragma mark - Timers

- (void) refreshTimeline:(NSTimer *)timer
{
	[self refreshTimeline];
}

@end
