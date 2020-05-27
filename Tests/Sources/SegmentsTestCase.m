//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"
#import "Segment.h"
#import "TestMacros.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

// Private headers
#import "SRGSegment+Private.h"

static NSURL *SegmentsOnDemandTestURL(void)
{
    return [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

static NSURL *SegmentsLiveTimestampTestURL(void)
{
    return [NSURL URLWithString:@"https://mcdn.daserste.de/daserste/int/master.m3u8"];
}

@interface SegmentsTestCase : MediaPlayerBaseTestCase

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
    [self.mediaPlayerController reset];
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testEquality
{
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment3 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    
    Segment *blockedSegment1 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *blockedSegment2 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *blockedSegment3 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    
    Segment *hiddenSegment1 = [Segment hiddenSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *hiddenSegment2 = [Segment hiddenSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *hiddenSegment3 = [Segment hiddenSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    
    XCTAssertTrue(SRGMediaPlayerAreEqualSegments(segment1, segment2));
    XCTAssertFalse(SRGMediaPlayerAreEqualSegments(segment1, segment3));
    
    XCTAssertTrue(SRGMediaPlayerAreEqualSegments(blockedSegment1, blockedSegment2));
    XCTAssertFalse(SRGMediaPlayerAreEqualSegments(blockedSegment1, blockedSegment3));
    
    XCTAssertTrue(SRGMediaPlayerAreEqualSegments(hiddenSegment1, hiddenSegment2));
    XCTAssertFalse(SRGMediaPlayerAreEqualSegments(hiddenSegment1, hiddenSegment3));
    
    XCTAssertFalse(SRGMediaPlayerAreEqualSegments(segment1, blockedSegment1));
    XCTAssertFalse(SRGMediaPlayerAreEqualSegments(segment1, hiddenSegment1));
    XCTAssertFalse(SRGMediaPlayerAreEqualSegments(blockedSegment1, hiddenSegment1));
}

- (void)testVisibleSegments
{
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment1, segment2] userInfo:nil];
    XCTAssertEqual(self.mediaPlayerController.visibleSegments.count, 2);
}

- (void)testHiddenSegments
{
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment hiddenSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment1, segment2] userInfo:nil];
    XCTAssertEqual(self.mediaPlayerController.visibleSegments.count, 1);
}

- (void)testSegmentPlaythrough
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.currentSegment, segment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 5);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testBlockedSegmentPlaythrough
{
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);       // Still playing right before skipping
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateSeeking);
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testNoStartOrEndNotificationsForBlockedSegments
{
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    // Ensure that no segment transition notifications are emitted
    id startObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
    }];
    id endObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment end notification must not be called");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:startObserver];
        [NSNotificationCenter.defaultCenter removeObserver:endObserver];
    }];
}

- (void)testSegmentAtStartPlaythrough
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 3);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testBlockedSegmentAtStartPlaythrough
{
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateSeeking);
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testContiguousSegments
{
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment1, segment2] userInfo:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment1);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerNextSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 5);
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 5);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment2);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 9);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

// No particular order is guaranteed for skip notifications belong to different segments. The only guaranteed behavior
// is that the skip end notification for a segment will be received after the skip start of the same segment
- (void)testContiguousBlockedSegments
{
    Segment *segment1 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment1, segment2] userInfo:nil];
    
    __block BOOL segment1WillSkipReceived = NO;
    __block BOOL segment2WillSkipReceived = NO;
    
    __block BOOL segment1DidSkipReceived = NO;
    __block BOOL segment2DidSkipReceived = NO;
    
    [self expectationForSingleNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        if (segment == segment1) {
            XCTAssertFalse(segment1DidSkipReceived);
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
            segment1WillSkipReceived = YES;
        }
        else if (segment == segment2) {
            XCTAssertFalse(segment2DidSkipReceived);
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);        // Two seeks in a row, get original playback position
            segment2WillSkipReceived = YES;
        }
        else {
            XCTFail(@"Unexpected skip notification received");
        }
        
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        
        return segment1WillSkipReceived && segment2WillSkipReceived;
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        if (segment == segment1) {
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
            segment1DidSkipReceived = YES;
        }
        else if (segment == segment2) {
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);        // Two seeks in a row, get original playback position
            segment2DidSkipReceived = YES;
        }
        else {
            XCTFail(@"Unexpected skip notification received");
        }
        
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        
        return segment1DidSkipReceived && segment2DidSkipReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testSeparateBlockedSegmentsAtStart
{
    Segment *segment1 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment1, segment2] userInfo:nil];
    
    __block BOOL segment1WillSkipReceived = NO;
    __block BOOL segment2WillSkipReceived = NO;
    
    __block BOOL segment1DidSkipReceived = NO;
    __block BOOL segment2DidSkipReceived = NO;
    
    [self expectationForSingleNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        if (segment == segment1) {
            XCTAssertFalse(segment1DidSkipReceived);
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
            segment1WillSkipReceived = YES;
        }
        else if (segment == segment2) {
            XCTAssertFalse(segment2DidSkipReceived);
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 5);
            segment2WillSkipReceived = YES;
        }
        else {
            XCTFail(@"Unexpected skip notification received");
        }
        
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        
        return segment1WillSkipReceived && segment2WillSkipReceived;
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        if (segment == segment1) {
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
            segment1DidSkipReceived = YES;
        }
        else if (segment == segment2) {
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 5);
            segment2DidSkipReceived = YES;
        }
        else {
            XCTFail(@"Unexpected skip notification received");
        }
        
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        
        return segment1DidSkipReceived && segment2DidSkipReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testContiguousBlockedSegmentsAtStart
{
    Segment *segment1 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    Segment *segment2 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment1, segment2] userInfo:nil];
    
    __block BOOL segment1WillSkipReceived = NO;
    __block BOOL segment2WillSkipReceived = NO;
    
    __block BOOL segment1DidSkipReceived = NO;
    __block BOOL segment2DidSkipReceived = NO;
    
    [self expectationForSingleNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        if (segment == segment1) {
            XCTAssertFalse(segment1DidSkipReceived);
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
            segment1WillSkipReceived = YES;
        }
        else if (segment == segment2) {
            XCTAssertFalse(segment2DidSkipReceived);
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
            segment2WillSkipReceived = YES;
        }
        else {
            XCTFail(@"Unexpected skip notification received");
        }
        
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        
        return segment1WillSkipReceived && segment2WillSkipReceived;
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        if (segment == segment1) {
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
            segment1DidSkipReceived = YES;
        }
        else if (segment == segment2) {
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
            segment2DidSkipReceived = YES;
        }
        else {
            XCTFail(@"Unexpected skip notification received");
        }
        
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        
        return segment1DidSkipReceived && segment2DidSkipReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testSegmentContiguousToBlockedSegment
{
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment1, segment2] userInfo:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment1);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 5);
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 5);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateSeeking);
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 5);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testSegmentTransitionFromBlockedSegment
{
    Segment *segment1 = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment1, segment2] userInfo:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateSeeking);
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    // Notifications for a transition may be sent one after the other. Use a common waiting point to be sure to trap them both
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment2);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 9);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testSeekIntoSegmentWithoutSelection
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(200., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    // Wait until the player is playing
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Seek into the segment
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);        // Seek was made from 0
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 220);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:220.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testSeekIntoSegmentWithSelection
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(200., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    // Wait until the player is playing
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Seek into the segment
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);        // Seek was made from 0
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 220);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:20.] inSegmentAtIndex:0 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testSeekBeforeSegmentWithSelection
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(200., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    // Wait until the player is playing
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Seek into the segment
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);        // Seek was made from 0
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 200);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:-20.] inSegmentAtIndex:0 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testSeekAfterSegmentWithSelection
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(200., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    // Wait until the player is playing
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Seek into the segment
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);        // Seek was made from 0
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 260);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:300.] inSegmentAtIndex:0 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testSeekIntoBlockedSegment
{
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(200., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    // Expect no segment start notificaton
    id startObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
    }];
    
    // Wait until the player is playing
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:startObserver];
    }];
    
    // Seek into the blocked segment
    [self expectationForSingleNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);                   // Still playing right before skipping
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);        // Seek is attempted from 0
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);        // Seek is attempted from 0
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:220.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    // Let playback continue for a while. No other events expected
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No other playback event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testStartTimeInSegmentWithoutSelection
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 30);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:30.] withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testStartTimeInSegmentWithSelection
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 30);       // Playback began at 30
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:[SRGPosition positionAtTimeInSeconds:10.] inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testStartTimeBeforeSegmentWithSelection
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:[SRGPosition positionAtTimeInSeconds:-10.] inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testStartTimeAterSegmentWithSelection
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:[SRGPosition positionAtTimeInSeconds:200.] inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testStartTimeNearBeginningOfSegmentWithSelectionAndTolerances
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        
        CMTime time = [notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue];
        TestAssertAlmostButNotEqual(time, 22., 4.);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:[SRGPosition positionAtTimeInSeconds:1.] inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testStartTimeNearEndOfSegmentWithSelectionAndTolerances
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        
        CMTime time = [notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue];
        TestAssertAlmostButNotEqual(time, 79., 4.);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:[SRGPosition positionAroundTimeInSeconds:59.] inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testStartTimeNearSegmentEndWithSelectionButWithoutEndTolerance
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 79);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:[SRGPosition positionAtTimeInSeconds:59.] inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testStartTimeNearSegmentEndWithSelectionAndEndTolerance
{
    self.mediaPlayerController.endTolerance = 2.;
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:[SRGPosition positionAtTimeInSeconds:59.] inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testSeekBetweenSegments
{
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(200., NSEC_PER_SEC), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 30);       // Playback began at 30
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:30.] withSegments:@[segment1, segment2] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment1);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerNextSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 30);
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 30);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:210.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment2);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testSeekWithinCurrentSegment
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))];
    
    // Wait until playing the segment normally
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 30);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:30.] withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    // Ensure that no segment end notification is emitted
    id endObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment end notification must not be called");
    }];
    
    // Wait until playing again
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:50.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:endObserver];
    }];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testSeekOutOfCurrentSegment
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))];
    
    // Wait until playing the segment normally
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 30);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:30.] withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    // Expect the segment to end
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 30);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:300.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testSelectedSegmentPlaythrough
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(10., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Programmatically seek to the segment
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
    
    // Pause playback. Since this playback event does not result from a segment selection, its selected flag must not be set
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Resume playback and wait until the segment normally ends
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 13);
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testConsecutiveSegmentSelection
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(10., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment1, segment2] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Programmatically seek to the first segment
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment1 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment1);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment1);
    
    // Programmatically select the second segment
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerNextSegmentKey], segment2);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 10);
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment1);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 10);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment2);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment2);
}

- (void)testRepeatedSegmentSelection
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(10., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Select the segment
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
    
    // Must receive end and start notifications for the segment again
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerNextSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 10);
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 10);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testSegmentSelectionWhileAlreadyPlayingItNormally
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    // Wait until playing the segment normally
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    // Select the segment. Expect a start notification because of the selection
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testBlockedSegmentSelection
{
    // Ensure that no segment start notification is emitted
    id startObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
    }];
    
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:startObserver];
    }];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testPrepareToPlaySegmentAtIndex
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:SegmentsOnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withUserInfo:nil completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testPlaySegmentAtIndex
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))];
    
    // Ensure that no seek notification is emitted
    id seekObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking) {
            XCTFail(@"Seek notification must not be called");
        }
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:seekObserver];
    }];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testPrepareToPlayBlockedSegmentAtIndex
{
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:SegmentsOnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withUserInfo:nil completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testPlayBlockedSegmentAtIndex
{
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testPlaySegmentAtIndexWithoutSegments
{
    // Ensure that no segment start notification is emitted
    id startObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
    }];
    
    // Check playback during 5 seconds
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Incorrect. Playback will start at the default location.
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:nil inSegments:@[] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:startObserver];
    }];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testPlaySelectedSegmentWithInvalidIndex
{
    // Ensure that no segment start notification is emitted
    id startObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Segment start notification must not be called");
    }];
    
    // Check playback during 5 seconds
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Incorrect. Playback will start at the default location. Check that nothing
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:10 position:nil inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:startObserver];
    }];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testPlaySelectedSegmentAtStreamEnd
{
    // Precise timing information gathered from the stream itself
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1795.045, NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1795);
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1800);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testResetWhilePlayingSelectedSegment
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSelectedSegmentKey], segment);
        
        XCTAssertNil(self.mediaPlayerController.currentSegment);
        XCTAssertNil(self.mediaPlayerController.selectedSegment);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testResetWhilePlayingNonSelectedSegment
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:[SRGPosition positionAtTime:CMTimeMakeWithSeconds(18., NSEC_PER_SEC)] withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
    XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSelectedSegmentKey]);
        
        XCTAssertNil(self.mediaPlayerController.currentSegment);
        XCTAssertNil(self.mediaPlayerController.selectedSegment);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testPlayAfterStopWithSegments
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))];
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSelectedSegmentKey], segment);
        
        XCTAssertNil(self.mediaPlayerController.currentSegment);
        XCTAssertNil(self.mediaPlayerController.selectedSegment);
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
    
    // Call -play after -stop. Playback must restart with the same conditions
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 20);
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
}

- (void)testSegmentsWithDates
{
    NSDate *segment1FromDate = [NSDate dateWithTimeIntervalSinceNow:-30. * 60.];
    NSDate *segment1ToDate = [segment1FromDate dateByAddingTimeInterval:10.];
    
    NSDate *segment2FromDate = [NSDate dateWithTimeIntervalSinceNow:-20. * 60.];
    NSDate *segment2ToDate = [segment2FromDate dateByAddingTimeInterval:20.];
    
    Segment *segment1 = [Segment segmentFromDate:segment1FromDate toDate:segment1ToDate];
    Segment *segment2 = [Segment segmentFromDate:segment2FromDate toDate:segment2ToDate];
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertNotNil(self.mediaPlayerController.currentDate);
        TestAssertAlmostEqualDate(self.mediaPlayerController.currentDate, segment1FromDate, 0.5);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:SegmentsLiveTimestampTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertNotNil(self.mediaPlayerController.currentDate);
        TestAssertAlmostEqualDate(self.mediaPlayerController.currentDate, segment2FromDate, 0.5);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testStartOnSegmentOutsideAvailableTimeRange
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(365 * 24 * 60 * 60., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 1800);
}

- (void)testSeekToSegmentOutsideAvailableTimeRange
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(365 * 24 * 60 * 60., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:SegmentsOnDemandTestURL() atPosition:nil withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 1800);
}

@end
