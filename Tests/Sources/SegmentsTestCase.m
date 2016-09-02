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
        XCTFail(@"Segment end notification must not be called");
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

- (void)testSeekIntoSegment
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(200., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    // Wait until the player is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
        return YES;
    }];
    
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Seek into the segment
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    
    [mediaPlayerController seekToTime:CMTimeMakeWithSeconds(220., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekIntoBlockedSegment
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(200., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    // Expect no segment start notificaton
    __block id startObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
        [[NSNotificationCenter defaultCenter] removeObserver:startObserver];
    }];
    
    // Wait until the player is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
        return YES;
    }];
    
    [mediaPlayerController playURL:SegmentsTestURL() withSegments:@[segment]];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Seek into the blocked segment
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] name], @"segment");
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerProgrammaticKey] boolValue]);
        return YES;
    }];
    
    [mediaPlayerController seekToTime:CMTimeMakeWithSeconds(220., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testProgrammaticSegmentPlay
{
    
}

- (void)testProgrammaticBlockedSegmentPlay
{
    
}

- (void)testProgrammaticSegmentPlayAfterProgrammaticSegmentPlay
{

}

@end
