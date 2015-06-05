//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "PseudoILDataProvider.h"
#import "Segment.h"

#define foo4random() (arc4random() % ((unsigned)RAND_MAX + 1))

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
		Segment *fullLength = [[Segment alloc] initWithStart:0 duration:duration title:@"fullLength"];
		
		NSMutableArray *segments = [NSMutableArray array];
		NSInteger row = [identifier integerValue];
		
		if (row == 0) {
			// 3 visible segments
			for (NSUInteger i = 0; i < 3; i++) {
				Segment *segment = [[Segment alloc] initWithStart:5*(i*5+1) duration:10 title:[NSString stringWithFormat:@"Segment #%@", @(i)]];
				[segments addObject:segment];
			}
		}
		else if (row == 1) {
			// 5 segments, 2 visible
			for (NSUInteger i = 0; i < 5; i++) {
				Segment *segment = [[Segment alloc] initWithStart:5*(i*5+1) duration:10 title:[NSString stringWithFormat:@"Segment #%@", @(i)]];
				segment.visible = (i%2 != 0);
				[segments addObject:segment];
			}
		}
		else if (row == 2) {
			// 3 segments, 2 blocked
			for (NSUInteger i = 0; i < 3; i++) {
				BOOL blocked = (i%2 != 0);
				NSString *title = [NSString stringWithFormat:@"%@Segment #%@", (blocked) ? @"Blocked ": @"", @(i)];
				Segment *segment = [[Segment alloc] initWithStart:5*(i*5+1) duration:10 title:title];
				segment.blocked = blocked;
				[segments addObject:segment];
			}
		}
		else if (row == 3) {
			// Blocked segment at start
			for (NSUInteger i = 0; i < 3; i++) {
				BOOL blocked = (i == 0);
				NSString *title = [NSString stringWithFormat:@"%@Segment #%@", (blocked) ? @"Blocked ": @"", @(i)];
				Segment *segment = [[Segment alloc] initWithStart:25*i duration:10 title:title];
				segment.blocked = blocked;
				[segments addObject:segment];
			}
		}
		else if (row == 4) {
			// 10 segments, 8 visible, 5 blocked;
			for (NSUInteger i = 0; i < 10; i++) {
				BOOL blocked = (i%2 == 0);
				NSString *title = [NSString stringWithFormat:@"%@Segment #%@", (blocked) ? @"Blocked ": @"", @(i)];
				Segment *segment = [[Segment alloc] initWithStart:5*(i*5+1) duration:10 title:title];
				segment.blocked = blocked;
				segment.visible = (i > 1);
				[segments addObject:segment];
			}
		}
		else if (row == 5) {
			// Error
			
		}
		
		completionHandler(fullLength, segments, nil);
	}
}

@end
