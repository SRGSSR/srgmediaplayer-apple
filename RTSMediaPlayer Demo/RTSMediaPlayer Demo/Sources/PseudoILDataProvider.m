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
	if ([identifier isEqualToString:@"error"]) {
		completionHandler(nil, [NSError errorWithDomain:@"Demo" code:123456 userInfo:@{NSLocalizedDescriptionKey: @"error"}]);
	}
	else {
		// 19:30 RTS, token unnecessary. Length: 31:57.
		completionHandler([NSURL URLWithString:@"http://rtsch-i.akamaihd.net/i/tj/2015/tj_20150601_full_f_859152-,101,701,1201,k.mp4.csmil/master.m3u8"], nil);
	}	
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

#pragma mark - RTSMediaSegmentsDataSource protocol

- (void) segmentsController:(RTSMediaSegmentsController *)controller
	  segmentsForIdentifier:(NSString *)identifier
	  withCompletionHandler:(RTSMediaSegmentsCompletionHandler)completionHandler
{
	if ([identifier isEqualToString:@"error"]) {
		completionHandler(nil, nil, [NSError errorWithDomain:@"Demo" code:123456 userInfo:@{NSLocalizedDescriptionKey: @"error"}]);
	}
	else {
		double duration = 31.0*60.0 + 57.0;
		Segment *fullLength = [[Segment alloc] initWithStartTime:0 duration:duration title:@"fullLength" blocked:NO visible:YES];
		
		NSMutableArray *segments = [NSMutableArray array];
		for (NSUInteger i = 0; i < 3; i++) {
			Segment *segment = [[Segment alloc] initWithStartTime:5*(i*5+1) duration:10 title:[NSString stringWithFormat:@"Segment #%ld", i] blocked:NO visible:YES];
			[segments addObject:segment];
		}
		
		completionHandler(fullLength, segments, nil);
	}
}

@end
