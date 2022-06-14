//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"

@import libextobjc;
@import MAKVONotificationCenter;

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

static NSURL *LiveTestURL(void)
{
    return [NSURL URLWithString:@"https://rtsc3video.akamaized.net/hls/live/2042837/c3video/3/playlist.m3u8?dw=0"];
}

static NSURL *DVRTestURL(void)
{
    return [NSURL URLWithString:@"https://rtsc3video.akamaized.net/hls/live/2042837/c3video/3/playlist.m3u8"];
}

@import SRGMediaPlayer;

@interface RateTestCase : MediaPlayerBaseTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation RateTestCase

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

- (void)testPlaybackStartAtRate
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.playbackRate = 2.f;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
}

- (void)testRateChangeDuringPlayback
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    self.mediaPlayerController.playbackRate = 2.f;
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
}

- (void)testRateChangeDuringPause
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    self.mediaPlayerController.playbackRate = 2.f;
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 0.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
}

- (void)testRatePreservationAfterPause
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.playbackRate = 2.f;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 0.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
}

- (void)testRatePreservationAfterSeek
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.playbackRate = 2.f;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:10.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
}

- (void)testRatePreservationAfterStop
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.playbackRate = 2.f;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.player);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
}

- (void)testRatePreservationForSubsequentPlayback
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.playbackRate = 2.f;
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
}

- (void)testDVRPlaybackLiveEdgeEffectivePlaybackRateAdjustments
{
    // Start at the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.playbackRate = 2.f;
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    // Move away from the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(50., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
    
    // Keep playing until we catch up with the live edge again
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, effectivePlaybackRate) expectedValue:@1];

    [self waitForExpectationsWithTimeout:100. handler:nil];

    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
}

- (void)testDVRInitialFastEffectivePlaybackRateStability
{
    // Start at the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.playbackRate = 2.f;
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    // Move a bit from the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(15., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    // Play for a while. The effective playback rate must remain constant
    id effectivePlaybackRateObservation = [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, effectivePlaybackRate) options:0 block:^(MAKVONotification *notification) {
        XCTFail(@"No effective playback rate change must occur");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [MAKVONotificationCenter.defaultCenter removeObservation:effectivePlaybackRateObservation];
    }];
}

- (void)testDVRInitialSlowEffectivePlaybackRateStability
{
    // Start at the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.playbackRate = 0.5f;
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 0.5f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 0.5f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 0.5f);
    
    // Move a bit from the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(15., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 0.5f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 0.5f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 0.5f);
    
    // Play for a while. The effective playback rate must remain constant
    id effectivePlaybackRateObservation = [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, effectivePlaybackRate) options:0 block:^(MAKVONotification *notification) {
        XCTFail(@"No effective playback rate change must occur");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [MAKVONotificationCenter.defaultCenter removeObservation:effectivePlaybackRateObservation];
    }];
}

- (void)testDVRChangedFastEffectivePlaybackRateStability
{
    // Start at the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    // Move a bit from the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(15., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    // Change the playback rate
    self.mediaPlayerController.playbackRate = 2.f;
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    // Play for a while. The effective playback rate must remain constant
    id effectivePlaybackRateObservation = [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, effectivePlaybackRate) options:0 block:^(MAKVONotification *notification) {
        XCTFail(@"No effective playback rate change must occur");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [MAKVONotificationCenter.defaultCenter removeObservation:effectivePlaybackRateObservation];
    }];
}

- (void)testDVRChangedSlowEffectivePlaybackRateStability
{
    // Start at the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    // Move a bit from the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(15., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    // Change the playback rate
    self.mediaPlayerController.playbackRate = 0.5f;
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 0.5f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 0.5f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 0.5f);
    
    // Play for a while. The effective playback rate must remain constant
    id effectivePlaybackRateObservation = [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, effectivePlaybackRate) options:0 block:^(MAKVONotification *notification) {
        XCTFail(@"No effective playback rate change must occur");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [MAKVONotificationCenter.defaultCenter removeObservation:effectivePlaybackRateObservation];
    }];
}

- (void)testDVRSlowRateChangesNearLiveEdge
{
    // Start at the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    // Move a bit from the edge
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(15., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
    
    // Change the playback rate
    self.mediaPlayerController.playbackRate = 0.5f;
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 0.5f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 0.5f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 0.5f);
    
    // Change the playback rate to a higher slow rate
    self.mediaPlayerController.playbackRate = 0.75f;
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 0.75f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 0.75f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 0.75f);
}

- (void)testLivestreamFastPlayback
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.playbackRate = 2.f;
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 2.f);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
}

- (void)testLivestreamSlowPlayback
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.playbackRate = 0.5f;
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 0.5f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 0.5f);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 0.5f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 0.5f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 0.5f);
}

- (void)testPlaybackRateKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, playbackRate) expectedValue:@2];
    self.mediaPlayerController.playbackRate = 2.f;
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, playbackRate) expectedValue:@0.5];
    self.mediaPlayerController.playbackRate = 0.5f;
    [self waitForExpectationsWithTimeout:10. handler:nil];
}

- (void)testEffectivePlaybackRateKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, effectivePlaybackRate) expectedValue:@2];
    self.mediaPlayerController.playbackRate = 2.f;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, effectivePlaybackRate) expectedValue:@0.5];
    self.mediaPlayerController.playbackRate = 0.5f;
    [self waitForExpectationsWithTimeout:10. handler:nil];
}

- (void)testSupportedPlaybackRates
{
    self.mediaPlayerController.playbackRate = 0.5;
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 0.5f);
    
    self.mediaPlayerController.playbackRate = 0.75;
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 0.75f);
    
    self.mediaPlayerController.playbackRate = 1.f;
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.f);
    
    self.mediaPlayerController.playbackRate = 1.25f;
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.25f);
    
    self.mediaPlayerController.playbackRate = 1.5f;
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.5f);
    
    self.mediaPlayerController.playbackRate = 2.f;
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 2.f);
}

- (void)testUnsupportedPlaybackRates
{
    self.mediaPlayerController.playbackRate = -3.f;
    self.mediaPlayerController.playbackRate = 0.f;
    self.mediaPlayerController.playbackRate = 0.1f;
    self.mediaPlayerController.playbackRate = 4.f;
    
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.f);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.player.rate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.playbackRate, 1.f);
    XCTAssertEqual(self.mediaPlayerController.effectivePlaybackRate, 1.f);
}

@end
