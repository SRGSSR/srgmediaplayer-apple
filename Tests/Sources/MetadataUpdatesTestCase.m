//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"
#import "TestMacros.h"
#import "XCTestCase+MediaPlayerTests.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <XCTest/XCTest.h>

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

@interface MetadataUpdatesTestCase : XCTestCase

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

- (void)testSegmentRemovalWhileSeekingInsideIt
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

- (void)testSegmentRemovalWhileSeekingOutsideIt
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

- (void)testSelectedSegmentRemovalWhilePlaying
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 inSegments:@[segment] withUserInfo:nil];
    
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

- (void)testSelectedSegmentRemovalWhileSeekingInsideIt
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 inSegments:@[segment] withUserInfo:nil];
    
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

- (void)testSelectedSegmentRemovalWhileSeekingOutsideIt
{
    [self mpt_expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.mediaPlayerController handler:nil];
    
    Segment *segment = [Segment segmentWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1., NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 inSegments:@[segment] withUserInfo:nil];
    
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

- (void)testSegmentUpdateWhilePlaying
{
    
}

- (void)testSegmentAdditionWhilePaused
{
    
}

- (void)testSegmentRemovalWhilePaused
{
    
}

- (void)testSelectedSegmentRemovalWhilePaused
{
    
}

- (void)testSegmentUpdateWhilePaused
{
    
}

- (void)testSegmentUpdateWhileSeekingInsideIt
{
    
}

- (void)testBlockedSegmentAdditionWhilePlaying
{
    
}

- (void)testBlockedSegmentAdditionWhilePaused
{
    
}

- (void)testBlockedSegmentAdditionWhileSeeking
{
    
}

- (void)testSegmentAdditionAtSeekLocation
{
    
}

- (void)testBlockedSegmentAdditionAtSeekLocation
{
    
}

- (void)testSegmentRemovalAtSeekLocation
{
    
}

- (void)testBlockedSegmentRemovalAtSeekLocation
{
    
}

- (void)testBlockedSegmentRemovalWhileSkippingIt
{
    
}

@end
