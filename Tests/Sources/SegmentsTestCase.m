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

// Expect seek notifications skipping the segment
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

// Expect segment start / end notifications
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

// Expect seek notifications skipping the segment
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

// Expect segment end and start notifications
- (void)testConsecutiveSegments
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
    
    // The transition notifications are sent one after the other. Use a common waiting point for both
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

// Expect two skips, one for the first segment, another one for the second one
- (void)testContiguousBlockedSegments
{

}

// Expect two skips, one for the first segment, another one for the second one
- (void)testContiguousBlockedSegmentsAtStart
{
    
}

// Expect single seek for the first segment. Playback resumes where no blocking takes place, but no events for the second
// segment are received
- (void)testSegmentTransitionIntoBlockedSegment
{

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
