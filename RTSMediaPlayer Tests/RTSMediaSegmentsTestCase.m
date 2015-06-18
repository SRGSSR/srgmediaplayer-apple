//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <XCTest/XCTest.h>
#import <RTSMediaPlayer/RTSMediaPlayer.h>

#import "Segment.h"

@interface SegmentsDataSource : NSObject <RTSMediaSegmentsDataSource>

@end

@interface RTSMediaSegmentsTestCase : XCTestCase

@property (nonatomic) RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic) SegmentsDataSource *segmentsDataSource;
@property (nonatomic) RTSMediaSegmentsController *mediaSegmentsController;

@end

@implementation RTSMediaSegmentsTestCase

#pragma mark - Setup and teardown

- (void) setUp
{
	NSURL *url = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentURL:url];
	
	self.segmentsDataSource = [[SegmentsDataSource alloc] init];
	
	self.mediaSegmentsController = [[RTSMediaSegmentsController alloc] init];
	self.mediaSegmentsController.dataSource = self.segmentsDataSource;
	self.mediaSegmentsController.playerController = self.mediaPlayerController;
}

- (void) tearDown
{
	self.mediaPlayerController = nil;
	self.mediaSegmentsController = nil;
	self.segmentsDataSource = nil;
}

#pragma mark - Tests



// TODO: Test
// 1) Segment start / end / switch / seek for:
//      - visible segments
//      - blocked segments
//      - hidden segments
//      - blocked segment at start
// 2) Segment errors
// 3) Closing the player while a segment is being played

@end

@implementation SegmentsDataSource

- (void) segmentsController:(RTSMediaSegmentsController *)controller segmentsForIdentifier:(NSString *)identifier withCompletionHandler:(RTSMediaSegmentsCompletionHandler)completionHandler
{
	Segment *fullLength = [[Segment alloc] initWithName:@"full_length" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., 1.))];
	
	if ([identifier isEqualToString:@"segment"])
	{
		Segment *segment = [[Segment alloc] initWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.))];
		completionHandler(fullLength, @[segment], nil);
	}
	else if ([identifier isEqualToString:@"blocked_segment"])
	{
		Segment *segment = [[Segment alloc] initWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.))];
		segment.blocked = YES;
		completionHandler(fullLength, @[segment], nil);
	}
	else if ([identifier isEqualToString:@"hidden_segment"])
	{
		Segment *segment = [[Segment alloc] initWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.))];
		segment.visible = NO;
		completionHandler(fullLength, @[segment], nil);
	}
	else if ([identifier isEqualToString:@"hidden_blocked_segment"])
	{
		Segment *segment = [[Segment alloc] initWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.))];
		segment.blocked = YES;
		segment.visible = NO;
		completionHandler(fullLength, @[segment], nil);
	}
	else if ([identifier isEqualToString:@"segment_at_start"])
	{
		Segment *segment = [[Segment alloc] initWithName:@"segment" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., 1.))];
		completionHandler(fullLength, @[segment], nil);
	}
	else if ([identifier isEqualToString:@"blocked_segment_at_start"])
	{
		Segment *segment = [[Segment alloc] initWithName:@"segment" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., 1.))];
		segment.blocked = YES;
		completionHandler(fullLength, @[segment], nil);
	}
	else if ([identifier isEqualToString:@"hidden_segment_at_start"])
	{
		Segment *segment = [[Segment alloc] initWithName:@"segment" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., 1.))];
		segment.blocked = YES;
		completionHandler(fullLength, @[segment], nil);
	}
	else if ([identifier isEqualToString:@"hidden_blocked_segment_at_start"])
	{
		Segment *segment = [[Segment alloc] initWithName:@"segment" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., 1.))];
		segment.blocked = YES;
		segment.visible = NO;
		completionHandler(fullLength, @[segment], nil);
	}
	else if ([identifier isEqualToString:@"segment_transition"])
	{
		Segment *segment1 = [[Segment alloc] initWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.))];
		Segment *segment2 = [[Segment alloc] initWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., 1.), CMTimeMakeWithSeconds(4., 1.))];
		completionHandler(fullLength, @[segment1, segment2], nil);
	}
	else if ([identifier isEqualToString:@"segment_transition_into_blocked_segment"])
	{
		Segment *segment1 = [[Segment alloc] initWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.))];
		Segment *segment2 = [[Segment alloc] initWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., 1.), CMTimeMakeWithSeconds(4., 1.))];
		segment2.blocked = YES;
		completionHandler(fullLength, @[segment1, segment2], nil);
	}
	else if ([identifier isEqualToString:@"segment_transition_from_blocked_segment"])
	{
		Segment *segment1 = [[Segment alloc] initWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.))];
		segment1.blocked = YES;
		Segment *segment2 = [[Segment alloc] initWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., 1.), CMTimeMakeWithSeconds(4., 1.))];
		completionHandler(fullLength, @[segment1, segment2], nil);
	}
	// TODO: Test setups for Seek + Play segment + play at time (into segment, blocked, etc)
	else
	{
		NSError *error = [NSError errorWithDomain:@"ch.rts.RTSMediaPlayer-tests" code:1 userInfo:@{ NSLocalizedDescriptionKey : @"No segment are available" }];
		completionHandler(nil, nil, error);
	}
}

@end
