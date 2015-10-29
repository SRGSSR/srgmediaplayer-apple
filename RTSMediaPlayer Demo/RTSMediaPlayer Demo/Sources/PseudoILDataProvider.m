//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
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
	else if ([identifier isEqualToString:@"bonus"]) {
		completionHandler([NSURL URLWithString:@"http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v"], nil);
	}
	else {
		// Length is 30 minutes
		completionHandler([NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"], nil);
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
		completionHandler(nil, [NSError errorWithDomain:@"Demo" code:123456 userInfo:@{NSLocalizedDescriptionKey: @"error"}]);
	}
	else {
		double duration = 31.0*60.0 + 57.0;
		Segment *fullLength = [[Segment alloc] initWithIdentifier:identifier name:@"Full length" start:0 duration:duration];
		fullLength.fullLength = YES;
		fullLength.visible = NO;
		
		NSMutableArray *segments = [NSMutableArray arrayWithObject:fullLength];
		NSInteger row = [identifier integerValue];
		NSError *error = nil;
		
		if (row == 0) {
			// 3 visible segments
			for (NSUInteger i = 0; i < 3; i++) {
				Segment *segment = [[Segment alloc] initWithIdentifier:identifier name:[NSString stringWithFormat:@"Segment #%@", @(i)] start:5*(i*5+1) duration:10];
				[segments addObject:segment];
			}
		}
		else if (row == 1) {
			// 5 segments, 2 visible
			for (NSUInteger i = 0; i < 5; i++) {
				Segment *segment = [[Segment alloc] initWithIdentifier:identifier name:[NSString stringWithFormat:@"Segment #%@", @(i)] start:5*(i*5+1) duration:10];
				segment.visible = (i%2 != 0);
				[segments addObject:segment];
			}
		}
		else if (row == 2) {
			// 3 segments, 2 blocked
			for (NSUInteger i = 0; i < 3; i++) {
				BOOL blocked = (i%2 != 0);
				NSString *name = [NSString stringWithFormat:@"%@Segment #%@", (blocked) ? @"Blocked ": @"", @(i)];
				Segment *segment = [[Segment alloc] initWithIdentifier:identifier name:name start:5*(i*5+1) duration:10];
				segment.blocked = blocked;
				[segments addObject:segment];
			}
		}
		else if (row == 3) {
			// Blocked segment at start
			for (NSUInteger i = 0; i < 3; i++) {
				BOOL blocked = (i == 0);
				NSString *name = [NSString stringWithFormat:@"%@Segment #%@", (blocked) ? @"Blocked ": @"", @(i)];
				Segment *segment = [[Segment alloc] initWithIdentifier:identifier name:name start:25*i duration:10];
				segment.blocked = blocked;
				[segments addObject:segment];
			}
		}
		else if (row == 4) {
			// 10 segments, 8 visible, 5 blocked;
			for (NSUInteger i = 0; i < 10; i++) {
				BOOL blocked = (i%2 == 0);
				NSString *name = [NSString stringWithFormat:@"%@Segment #%@", (blocked) ? @"Blocked ": @"", @(i)];
				Segment *segment = [[Segment alloc] initWithIdentifier:identifier name:name start:5*(i*5+1) duration:10];
				segment.blocked = blocked;
				segment.visible = (i > 1);
				[segments addObject:segment];
			}
		}
		else if (row == 5) {
			// Two consecutive segments
			Segment *segment1 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #0" start:2. duration:3.];
			[segments addObject:segment1];
			
			Segment *segment2 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #1" start:5. duration:4.];
			[segments addObject:segment2];
		}
		else if (row == 6) {
			// Two consecutive blocked segments
			Segment *segment1 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #0" start:2. duration:3.];
			segment1.blocked = YES;
			[segments addObject:segment1];
			
			Segment *segment2 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #1" start:5. duration:4.];
			segment2.blocked = YES;
			[segments addObject:segment2];
		}
		else if (row == 7) {
			// One full-length with several logical segments, followed by another full-length (e.g. bonus)
			// Two consecutive blocked segments
			Segment *episodeSegment1 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #0" start:2. duration:30.];
			[segments addObject:episodeSegment1];
			
			Segment *episodeSegment2 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #1" start:32. duration:20.];
			[segments addObject:episodeSegment2];
			
			Segment *episodeSegment3 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #2" start:52. duration:20.];
			[segments addObject:episodeSegment3];

			Segment *episodeSegment4 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #3" start:72. duration:30.];
			[segments addObject:episodeSegment4];

			Segment *episodeSegment5 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #4" start:110. duration:10.];
			[segments addObject:episodeSegment5];

			Segment *episodeSegment6 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #5" start:120. duration:500.];
			[segments addObject:episodeSegment6];

			Segment *episodeSegment7 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #6" start:650. duration:30.];
			[segments addObject:episodeSegment7];

			Segment *episodeSegment8 = [[Segment alloc] initWithIdentifier:identifier name:@"Segment #7" start:680. duration:40.];
			[segments addObject:episodeSegment8];
			
			Segment *bonusSegment = [[Segment alloc] initWithIdentifier:@"bonus" name:@"Bonus" start:0. duration:10. * 60.];
			[segments addObject:bonusSegment];
		}
		else {
			// Error
			error = [NSError errorWithDomain:@"Demo" code:999 userInfo:@{NSLocalizedDescriptionKey:@"Segments Demo Error"}];
		}
		
		completionHandler(segments, error);
	}
}

@end
