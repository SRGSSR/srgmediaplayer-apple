//
//  Created by Samuel Défago on 22.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "SwissTXTDataSource.h"
#import "Segment.h"

// TODO: A data source should share connections (if the same request is already running, add the block to a list, and call all
//       completion blocks at the end. Such a mechanism could (and should) be made available as a class, IMHO

@implementation SwissTXTDataSource

#pragma mark - RTSMediaPlayerControllerDataSource protocol

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
	   contentURLForIdentifier:(NSString *)identifier
			 completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	NSString *URLString = [NSString stringWithFormat:@"http://test.event.api.swisstxt.ch:80/v1/stream/srf/byEventItemIdAndType/%@/hls", identifier];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		if (error)
		{
			completionHandler(nil, error);
			return;
		}
		
		NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (!responseString)
		{
			NSError *responseError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
			completionHandler(nil, responseError);
		}
		responseString = [responseString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
		
		NSURL *URL = [NSURL URLWithString:responseString];
		completionHandler(URL, nil);
	}];
}

#pragma mark - RTSMediaSegmentsDataSource protocol

- (void) segmentsController:(RTSMediaSegmentsController *)controller
	  segmentsForIdentifier:(NSString *)identifier
	  withCompletionHandler:(RTSMediaSegmentsCompletionHandler)completionHandler
{
	NSString *URLString = [NSString stringWithFormat:@"http://test.event.api.swisstxt.ch:80/v1/highlights/srf/byEventItemId/%@", identifier];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		if (error)
		{
			completionHandler ? completionHandler(nil, nil, error) : nil;
			return;
		}
		
		id responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
		if (!responseObject || ![responseObject isKindOfClass:[NSArray class]])
		{
			NSError *parseError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotParseResponse userInfo:nil];
			completionHandler ? completionHandler(nil, nil, parseError) : nil;
			return;
		}
		
		NSMutableArray *segments = [NSMutableArray array];
		for (NSDictionary *highlight in responseObject)
		{
			// Note that the start date available from this JSON (streamStartDate) is not reliable and is retrieve using
			// another request
			NSDate *date = [NSDate dateWithTimeIntervalSince1970:[highlight[@"timestamp"] doubleValue]];
			NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[highlight[@"streamStartTime"] doubleValue]];
			CMTime time = CMTimeMake([date timeIntervalSinceDate:startDate], 1.);
			
			Segment *segment = [[Segment alloc] initWithTime:time title:highlight[@"title"] identifier:highlight[@"id"] date:date];
			if (segment) {
				[segments addObject:segment];
			}
		}
		
		completionHandler ? completionHandler(nil, [NSArray arrayWithArray:segments], nil) : nil;
	}];
}

@end
