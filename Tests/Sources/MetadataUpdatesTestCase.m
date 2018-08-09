//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"
#import "Segment.h"
#import "TestMacros.h"
#import "XCTestCase+MediaPlayerTests.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <XCTest/XCTest.h>

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

@interface MetadataUpdatesTestCase : MediaPlayerBaseTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation MetadataUpdatesTestCase

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

- (void)testSegmentAdditionWhilePlaying
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 3);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSegmentAdditionWhilePaused
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 3);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSegmentAdditionWhileSeeking
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSegmentRemovalWhilePlaying
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    
    self.mediaPlayerController.segments = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSegmentRemovalWhilePaused
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    
    self.mediaPlayerController.segments = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSegmentRemovalWhileSeekingInto
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(7., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    id segmentStartObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No segment start is expected");
    }];
    id segmentEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No segment end is expected");
    }];
    
    self.mediaPlayerController.segments = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:segmentStartObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:segmentEndObserver];
    }];
}

- (void)testSegmentRemovalWhileSeekingWithin
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    
    self.mediaPlayerController.segments = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSegmentRemovalWhileSeekingOutside
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(10., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    
    self.mediaPlayerController.segments = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSegmentSwapWhilePrepared
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment1] userInfo:nil completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC), CMTimeMakeWithSeconds(8., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment2];
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSegmentSwapWhilePlaying
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment1] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC), CMTimeMakeWithSeconds(8., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerNextSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment2];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSegmentSwapWhilePaused
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment1] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC), CMTimeMakeWithSeconds(8., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerNextSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment2];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSegmentSwapWhileSeekingInto
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment1] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC), CMTimeMakeWithSeconds(8., NSEC_PER_SEC))];
    
    id segmentEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No segment end is expected");
    }];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment2];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:segmentEndObserver];
    }];
}

- (void)testSegmentSwapWhileSeekingWithin
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment1] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC), CMTimeMakeWithSeconds(8., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment1);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerNextSegmentKey], segment2);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousSegmentKey], segment1);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment2];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSelectedSegmentRemovalWhilePlaying
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 time:kCMTimeZero inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    
    self.mediaPlayerController.segments = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSelectedSegmentRemovalWhilePaused
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 time:kCMTimeZero inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    
    self.mediaPlayerController.segments = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSelectedSegmentRemovalWhileSeekingWithin
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 time:kCMTimeZero inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    
    self.mediaPlayerController.segments = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSelectedSegmentRemovalWhileSeekingInto
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekToTime:kCMTimeZero inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 5);
        return YES;
    }];
    
    self.mediaPlayerController.segments = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSelectedSegmentRemovalWhileSeekingOutside
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 time:kCMTimeZero inSegments:@[segment] withUserInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(10., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerNextSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 1);
        return YES;
    }];
    
    self.mediaPlayerController.segments = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSelectedSegmentSwapWhilePrepared
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    Segment *segment1 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment1] userInfo:nil completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment2 = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC), CMTimeMakeWithSeconds(8., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment2);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment2];
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testBlockedSegmentAdditionWhilePlaying
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 3);
        return YES;
    }];
    [self mpt_expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 3);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testBlockedSegmentAdditionWhilePaused
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 3);
        return YES;
    }];
    [self mpt_expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 3);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testBlockedSegmentAdditionWhileSeeking
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 3);
        return YES;
    }];
    [self mpt_expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 3);
        return YES;
    }];
    
    self.mediaPlayerController.segments = @[segment];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testBlockedSegmentRemovalWhileSeekingWithin
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    [self mpt_expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withCompletionHandler:nil];
    self.mediaPlayerController.segments = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testBlockedSegmentRemovalWhileSkippingIt
{
    [self mpt_expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    Segment *segment = [Segment blockedSegmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self mpt_expectationForNotification:SRGMediaPlayerWillSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        
        self.mediaPlayerController.segments = nil;
        return YES;
    }];
    [self mpt_expectationForNotification:SRGMediaPlayerDidSkipBlockedSegmentNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSegmentKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(3., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSegmentUpdateWithEquivalentSegment
{
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerSegmentKey], segment);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[segment] userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id segmentStartObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No segment start is expected");
    }];
    id segmentEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidEndNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No segment end is expected");
    }];
    
    // Update with an equivalent segment. No segment transition is expected
    Segment *equivalentSegment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    self.mediaPlayerController.segments = @[equivalentSegment];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:segmentStartObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:segmentEndObserver];
    }];
}

@end
