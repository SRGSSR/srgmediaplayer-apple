//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <XCTest/XCTest.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

#import "Segment.h"

@interface SegmentsTestDataSource : NSObject <RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>

@end

@interface RTSMediaSegmentsTestCase : XCTestCase

@property (nonatomic) RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic) SegmentsTestDataSource *dataSource;
@property (nonatomic) RTSMediaSegmentsController *mediaSegmentsController;

@end

@implementation RTSMediaSegmentsTestCase

#pragma mark - Setup and teardown

- (void) setUp
{
	self.dataSource = [[SegmentsTestDataSource alloc] init];
	
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] init];
	self.mediaPlayerController.dataSource = self.dataSource;
	
	self.mediaSegmentsController = [[RTSMediaSegmentsController alloc] init];
	self.mediaSegmentsController.dataSource = self.dataSource;
	self.mediaSegmentsController.playerController = self.mediaPlayerController;
}

- (void) tearDown
{
	self.mediaPlayerController = nil;
	self.mediaSegmentsController = nil;
	self.dataSource = nil;
}

#pragma mark - Helpers

- (void) playIdentifier:(NSString *)identifier
{
	[self.mediaPlayerController playIdentifier:identifier];
	[self.mediaSegmentsController reloadSegmentsForIdentifier:identifier completionHandler:nil];
}

#pragma mark - Tests

// FIXME: Currently, these tests do not check the notification order in a strict way, only that the expected notifications are received. No test also ensures that
//        only the required events are received, not more. This could be improved by inserting waiting times between expectations. For the moment, I only inserted
//        a waiting time when the playback starts

// Expect segment start / end notifications
- (void) testSegmentPlaythrough
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"segment"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

// Expect seek notifications skipping the segment, as well as the usual start / end notifications
- (void) testBlockedSegmentPlaythrough
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"blocked_segment"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

// Expect segment start / end notifications, as for a visible segment
- (void) testHiddenSegmentPlaythrough
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"hidden_segment"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

// Expect seek notifications skipping the segment, as well as the usual start / end notifications
- (void) testHiddenBlockedSegment
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"hidden_blocked_segment"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];

}

// Expect segment start / end notifications
- (void) testSegmentAtStartPlaythrough
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"segment_at_start"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

// Expect seek notifications skipping the segment, as well as the usual start / end notifications
- (void) testBlockedSegmentAtStartPlaythrough
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"blocked_segment_at_start"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

// Expect segment start / end notifications, as for a visible segment
- (void) testHiddenSegmentAtStartPlaythrough
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"hidden_segment_at_start"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

// Expect seek notifications skipping the segment, as well as the usual start / end notifications
- (void) testHiddenBlockedSegmentAtStart
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"hidden_blocked_segment_at_start"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		
		return YES;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

// Expect segment switch
- (void) testConsecutiveSegments
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"consecutive_segments"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment1");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSwitch)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment1");
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment2");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

// Expect single seek for the first segment. Playback resumes where no blocking takes place, but no events for the second
// segment are received
- (void) testContiguousBlockedSegments
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"consecutive_blocked_segments"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment1");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment1");
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment1");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment1");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

// Expect single seek for the first segment. Playback resumes where no blocking takes place, but no events for the second
// segment are received
- (void) testContiguousBlockedSegmentsAtStart
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"consecutive_blocked_segments_at_start"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment1");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment1");
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment1");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment1");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

// Expect single seek for the first segment. Playback resumes where no blocking takes place, but no events for the second
// segment are received
- (void) testSegmentTransitionIntoBlockedSegment
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self playIdentifier:@"segment_transition_into_blocked_segment"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment1");
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment1");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		XCTAssertNotNil(notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey]);
		XCTAssertFalse([notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart)
		{
			return NO;
		}
		
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment2");
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlaybackSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL(NSNotification *notification) {
		if ([notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd)
		{
			return NO;
		}
		
		XCTAssertEqualObjects([notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment2");
		XCTAssertNil(notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey]);
		
		return YES;
	}];
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused;
	}];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void) testPlaySegmentAtIndex
{}

- (void) testSeekIntoSegment
{}

- (void) testPlayBlockedSegmentAtIndex
{}

- (void) testSeekIntoBlockedSegment
{}

@end

@implementation SegmentsTestDataSource

#pragma mark - RTSMediaPlayerControllerDataSource protocol

- (void)mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	NSURL *url = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
	completionHandler(url, nil);
}

#pragma mark - RTSMediaSegmentsDataSource protocol

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
		segment.visible = NO;
		completionHandler(fullLength, @[segment], nil);
	}
	else if ([identifier isEqualToString:@"hidden_blocked_segment_at_start"])
	{
		Segment *segment = [[Segment alloc] initWithName:@"segment" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., 1.))];
		segment.blocked = YES;
		segment.visible = NO;
		completionHandler(fullLength, @[segment], nil);
	}
	else if ([identifier isEqualToString:@"consecutive_segments"])
	{
		Segment *segment1 = [[Segment alloc] initWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.))];
		Segment *segment2 = [[Segment alloc] initWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., 1.), CMTimeMakeWithSeconds(4., 1.))];
		completionHandler(fullLength, @[segment1, segment2], nil);
	}
	else if ([identifier isEqualToString:@"consecutive_blocked_segments"])
	{
		Segment *segment1 = [[Segment alloc] initWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.))];
		segment1.blocked = YES;
		Segment *segment2 = [[Segment alloc] initWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., 1.), CMTimeMakeWithSeconds(4., 1.))];
		segment2.blocked = YES;
		completionHandler(fullLength, @[segment1, segment2], nil);
	}
	else if ([identifier isEqualToString:@"consecutive_blocked_segments_at_start"])
	{
		Segment *segment1 = [[Segment alloc] initWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., 1.), CMTimeMakeWithSeconds(3., 1.))];
		segment1.blocked = YES;
		Segment *segment2 = [[Segment alloc] initWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(3., 1.), CMTimeMakeWithSeconds(4., 1.))];
		segment2.blocked = YES;
		completionHandler(fullLength, @[segment1, segment2], nil);
	}
	else if ([identifier isEqualToString:@"segment_transition_into_blocked_segment"])
	{
		Segment *segment1 = [[Segment alloc] initWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.))];
		Segment *segment2 = [[Segment alloc] initWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., 1.), CMTimeMakeWithSeconds(4., 1.))];
		segment2.blocked = YES;
		completionHandler(fullLength, @[segment1, segment2], nil);
	}
	else
	{
		NSError *error = [NSError errorWithDomain:@"ch.rts.RTSMediaPlayer-tests" code:1 userInfo:@{ NSLocalizedDescriptionKey : @"No segment are available" }];
		completionHandler(nil, nil, error);
	}
}

@end
