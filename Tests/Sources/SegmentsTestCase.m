//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <XCTest/XCTest.h>

#import "Segment.h"

static NSURL *SegmentsTestURL(void)
{
    return [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

@interface SegmentsTestCase : XCTestCase
@end

@implementation SegmentsTestCase

#pragma mark - Tests

- (void)testSegmentPlaythrough
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment]];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentPlaythrough
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment]];
    
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNoStartOrEndNotificationsForBlockedSegments
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment]];
    
    // Ensure that no segment transition notifications are emitted
    __block id startObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
        [[NSNotificationCenter defaultCenter] removeObserver:startObserver];
    }];
    __block id endObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
        [[NSNotificationCenter defaultCenter] removeObserver:endObserver];
    }];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentAtStartPlaythrough
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment]];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentAtStartPlaythrough
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment]];
    
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testContiguousSegments
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment1, segment2]];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment1");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment1");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment2");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment2");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testContiguousBlockedSegments
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment1 = [Segment blockedSegmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment blockedSegmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment1, segment2]];
    
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment1");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment1");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment2");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment2");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testContiguousBlockedSegmentsAtStart
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment1 = [Segment blockedSegmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment blockedSegmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(3., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment1, segment2]];
    
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment1");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment1");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment2");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment2");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentContiguousToBlockedSegment
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment blockedSegmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment1, segment2]];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment1");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment1");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment2");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment2");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentTransitionFromBlockedSegment
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment1 = [Segment blockedSegmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment1, segment2]];
    
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment1");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment1");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment2");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment2");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

// Expect a start event for the given segment, with YES for the user-driven information flag
- (void)testProgrammaticSegmentPlay
{

}

// Expect a seek
- (void)testProgrammaticBlockedSegmentPlay
{
    
}

// Expect a start event for the given segment, with NO for the user-driven information flag (set only when calling -playSegment:)
- (void)testSeekIntoSegment
{

}

- (void)testSeekIntoBlockedSegment
{

}

// Expect a switch between the two segments
- (void)testUserTriggeredSegmentPlayAfterUserTriggeredSegmentPlay
{

}

@end
