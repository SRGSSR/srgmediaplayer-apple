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

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation SegmentsTestCase

#pragma mark Setup and teardown

- (void)setUp
{
    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
}

- (void)tearDown
{
    // Always ensure the player gets deallocated between tests
    [self.mediaPlayerController reset];
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testSegmentPlaythrough
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentPlaythrough
{
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNoStartOrEndNotificationsForBlockedSegments
{
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    // Ensure that no segment transition notifications are emitted
    __block id startObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
        [[NSNotificationCenter defaultCenter] removeObserver:startObserver];
    }];
    __block id endObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment end notification must not be called");
        [[NSNotificationCenter defaultCenter] removeObserver:endObserver];
    }];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentAtStartPlaythrough
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentAtStartPlaythrough
{
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testContiguousSegments
{
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment1, segment2] userInfo:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerNextSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testContiguousBlockedSegments
{
    Segment *segment1 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment1, segment2] userInfo:nil];
    
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testContiguousBlockedSegmentsAtStart
{
    Segment *segment1 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(3., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment1, segment2] userInfo:nil];
    
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentContiguousToBlockedSegment
{
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment1, segment2] userInfo:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentTransitionFromBlockedSegment
{
    Segment *segment1 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment1, segment2] userInfo:nil];
    
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekIntoSegment
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(200., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    // Wait until the player is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Seek into the segment
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController seekToTime:CMTimeMakeWithSeconds(220., NSEC_PER_SEC) withToleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekIntoBlockedSegment
{
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(200., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    // Expect no segment start notificaton
    __block id startObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
        [[NSNotificationCenter defaultCenter] removeObserver:startObserver];
    }];
    
    // Wait until the player is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Seek into the blocked segment
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController seekToTime:CMTimeMakeWithSeconds(220., NSEC_PER_SEC) withToleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testStartTimeInSegment
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekBetweenSegments
{
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(200., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withSegments:@[segment1, segment2] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerNextSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(210., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSelectedSegmentPlaythrough
{
    // Wait until playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];

    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(10., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Programmatically seek to the segment
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController seekToSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Wait until the segment normally ends
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testConsecutiveSegmentSelection
{
    // Wait until playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(10., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment1, segment2] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Programmatically seek to the first segment
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController seekToSegment:segment1 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Programmatically select the second segment
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerNextSegmentKey], segment2);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment1);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController seekToSegment:segment2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testRepeatedSegmentSelection
{
    // Wait until playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(10., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Select the segment
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController seekToSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Must receive end and start notifications for the segment again
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerNextSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController seekToSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionWhileAlreadyPlayingTheSegmentNormally
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    // Wait until playing the segment normally
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Select the segment. Expect a start notification because of the selection
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController seekToSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentSelection
{
    // Ensure that no segment start notification is emitted
    __block id startObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
        [[NSNotificationCenter defaultCenter] removeObserver:startObserver];
    }];
    
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekWithinCurrentSegment
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))];
    
    // Wait until playing the segment normally
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsTestURL() atTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Ensure that no segment transition notifications are emitted
    __block id startObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
        [[NSNotificationCenter defaultCenter] removeObserver:startObserver];
    }];
    // Ensure that no segment transition notifications are emitted
    __block id endObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment end notification must not be called");
        [[NSNotificationCenter defaultCenter] removeObserver:endObserver];
    }];
    
    // Wait until playing again
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(50., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekOutOfSelectedSegment
{
    XCTFail(@"TODO");
}

- (void)testPrepareSelectedSegment
{
    XCTFail(@"TODO");
}

- (void)testStartPlayingSelectedSegment
{
    XCTFail(@"TODO");
}

- (void)testPlaySelectedSegmentWithoutSegments
{
    XCTFail(@"TODO");
}

- (void)testPlaySelectedSegmentWithInvalidIndex
{
    XCTFail(@"TODO");
}

- (void)testPlayOutOfRangeSegment
{
    // Should probably receive both notifications
    XCTFail(@"TODO");
}

@end
