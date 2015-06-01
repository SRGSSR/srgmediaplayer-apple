//
//  PseudoILDataProvider.m
//  RTSMediaPlayer Demo
//
//  Created by Cédric Foellmi on 01/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "PseudoILDataProvider.h"
#import "Segment.h"

static NSString * const SRGILTokenHandlerBaseURLString = @"http://tp.srgssr.ch/token/akahd.json.xml?stream=/";

@implementation PseudoILDataProvider


#pragma mark - RTSMediaPlayerControllerDataSource protocol

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
	   contentURLForIdentifier:(NSString *)identifier
			 completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	NSString *businessUnit = nil;
	NSString *trueIdentifier = nil;
	if ([identifier isEqualToString:@"srf-0"]) {
		businessUnit = @"srf";
		trueIdentifier = @"e6657156-859c-414f-a3be-b18c12ccd3d7";
	}
	
	NSString *URLString = [NSString stringWithFormat:@"http://il.srgssr.ch/integrationlayer/1.0/ue/%@/video/play/%@.json",
						   businessUnit, trueIdentifier];
	
	[NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URLString]]
									   queue:[NSOperationQueue mainQueue]
						   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
							   if (error) {
								   completionHandler(nil, error);
								   return;
							   }
							   
							   NSDictionary *video = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
							   if (!video) {
								   NSError *e = [NSError errorWithDomain:@"Demo"
																	code:123456
																userInfo:@{NSLocalizedDescriptionKey: @"Can't create video object"}];
								   
								   completionHandler(nil, e);
								   return;
							   }
							   
							   NSString *URLString = nil;
							   NSArray *playlists = video[@"Video"][@"Playlists"][@"Playlist"];
							   for (NSDictionary *playlist in playlists) {
								   if ([[playlist objectForKey:@"@protocol"] isEqualToString:@"HTTP-HLS"]) {
									   URLString = [[playlist[@"url"] firstObject] objectForKey:@"text"];
									   break;
								   }
							   }
							   
							   if (!URLString) {
								   NSError *e = [NSError errorWithDomain:@"Demo"
																	code:123456
																userInfo:@{NSLocalizedDescriptionKey: @"Can't find URL in video object"}];
								   completionHandler(nil, e);
							   }
							   
							   NSURL *tokenURL = [self tokenRequestURLForURL:[NSURL URLWithString:URLString]];
							   
							   // SYNC network request
							   NSString *JSONString = [NSString stringWithContentsOfURL:tokenURL
																			   encoding:NSUTF8StringEncoding
																				  error:&error];
							   
							   NSError *deserializationError = nil;
							   NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:[JSONString dataUsingEncoding:NSUTF8StringEncoding]
																					options:0
																					  error:&deserializationError];
							   
							   NSMutableString *finalURLString = [URLString mutableCopy];
							   [finalURLString appendString:@"?"];
							   [finalURLString appendString:[JSON[@"token"] objectForKey:@"authparams"]];
							   
							   completionHandler([NSURL URLWithString:finalURLString], nil);
						   }];
}

- (NSURL *)tokenRequestURLForURL:(NSURL *)url
{
	NSAssert(url, @"One needs an URL here.");
	
	NSMutableArray *urlPaths = [NSMutableArray arrayWithArray:[url pathComponents]];
	
	[urlPaths removeObjectAtIndex:0];
	[urlPaths removeLastObject];
	[urlPaths addObject:@"*"];
	
	return [NSURL URLWithString:[SRGILTokenHandlerBaseURLString stringByAppendingString:[urlPaths componentsJoinedByString:@"/"]]];
}

#pragma mark - RTSMediaPlayerSegmentDataSource protocol

- (void) segmentsController:(RTSMediaSegmentsController *)controller
	  segmentsForIdentifier:(NSString *)identifier
	  withCompletionHandler:(RTSMediaSegmentsCompletionHandler)completionHandler
{
	if ([identifier isEqualToString:@"srf-0"]) {
		completionHandler(nil, nil, nil);
	}
	
//		completionHandler ? completionHandler(nil, [NSArray arrayWithArray:segments], nil) : nil;
}

@end
