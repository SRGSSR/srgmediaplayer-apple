//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "TimeshiftILDataProvider.h"
#import "Segment.h"

#define foo4random() (arc4random() % ((unsigned)RAND_MAX + 1))

static NSString * const SRGILTokenHandlerBaseURLString = @"http://tp.srgssr.ch/token/akahd.json.xml?stream=/";

@implementation TimeshiftILDataProvider


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

@end
