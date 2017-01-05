//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <XCTest/XCTest.h>

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

static NSURL *ShortNonStreamedTestURL(void)
{
    return [NSURL URLWithString:@"http://techslides.com/demos/sample-videos/small.mp4"];
}

static NSURL *LiveTestURL(void)
{
    return [NSURL URLWithString:@"http://fr-par-iphone-2.cdn.hexaglobe.net/streaming/euronews_ewns/9-live.m3u8"];
}

static NSURL *DVRTestURL(void)
{
    return [NSURL URLWithString:@"https://wowza.jwplayer.com/live/jelly.stream/playlist.m3u8?DVR"];
}

@interface PlaybackTestCase : XCTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation PlaybackTestCase

#pragma mark Helpers

- (XCTestExpectation *)expectationForElapsedTimeInterval:(NSTimeInterval)timeInterval withHandler:(void (^)(void))handler
{
    XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Wait for %@ seconds", @(timeInterval)]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
        handler ? handler() : nil;
    });
    return expectation;
}

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

- (void)testInitialPlayerState
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
}

- (void)testPrepare
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil completionHandler:^{
        // Upon completion handler entry, the state is always preparing
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // After completion handler execution, the player state is updated. Since nothing is done in the completion handler,
    // the player must be paused
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        // Check the next notification
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPrepareAndPlay
{
    XCTestExpectation *preparationExpectation = [self expectationWithDescription:@"Playing"];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil completionHandler:^{
        // Upon completion handler entry, the state is always preparing
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
        
        // If we now play, the player must immediately be in the playing state
        [self.mediaPlayerController play];
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
        
        [preparationExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testMultiplePrepare
{
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil completionHandler:^{
        XCTFail(@"The completion handler must not be called since a second prepare must cancel the first");
    }];
    
    XCTestExpectation *preparationExpectation = [self expectationWithDescription:@"Prepared"];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil completionHandler:^{
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
        [preparationExpectation fulfill];
    }];
    
   [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testWithoutPrepare
{
    // Playing does not alter the state of the player since it has not been prepared
    [self.mediaPlayerController play];
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
}

- (void)testPrepareToTimeOutsideMedia
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atTime:CMTimeMakeWithSeconds(24. * 60. * 60., NSEC_PER_SEC) withSegments:nil userInfo:nil completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // After completion handler execution, the player state is updated. Since nothing is done in the completion handler,
    // the player must be paused
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlay
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        // The player must have transitioned directly to the playing state without going through the paused state
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testFastPlayPausePlay
{
    // Play the media. Two events expected: Preparing and playing
    __block NSInteger count1 = 0;
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ++count1;
    }];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
    }];
    
    // Two events expected: preparing and playing
    XCTAssertEqual(count1, 2);

    __block NSInteger count2 = 0;
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ++count2;
    }];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
    
    // One event expected: paused
    XCTAssertEqual(count2, 1);
    
    __block NSInteger count3 = 0;
    id eventObserver3 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ++count3;
    }];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver3];
    }];
    
    // One event expected: playing
    XCTAssertEqual(count3, 1);
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver4 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver4];
    }];
}

- (void)testStreamedMediaPlaythrough
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Seek to the end (media is too long to be entirely played through :) )
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekEfficientlyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMake(3., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateEnded);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testNonStreamedMediaPlaythrough
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:ShortNonStreamedTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateEnded);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayAtStreamEnd
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Seek to the end (media is too long to be entirely played through :) ) and wait until playback ends
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    
    [self.mediaPlayerController seekEfficientlyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMake(3., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Play at the end. Expect restart at the beginning of the stream with no seek events
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateEnded);
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPauseAtStreamEnd
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Seek to the end (media is too long to be entirely played through :) ) and wait until playback ends
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    
    [self.mediaPlayerController seekEfficientlyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMake(3., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Pausing when the stream already ended must be a no-op");
    }];
    
    // Pause at the end. Nothing must happen, the player has already a rate of 0
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testLivePause
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaInformationAvailabilityAfterPrepare
{
    XCTestExpectation *preparationExpectation = [self expectationWithDescription:@"Prepared"];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil completionHandler:^{
        XCTAssertEqual(self.mediaPlayerController.mediaType, SRGMediaPlayerMediaTypeVideo);
        XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeOnDemand);
        [preparationExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testMediaInformationAvailabilityBeforePrepare
{
    XCTAssertEqual(self.mediaPlayerController.mediaType, SRGMediaPlayerMediaTypeUnknown);
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeUnknown);
}

- (void)testOnDemandProperties
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeOnDemand);
    XCTAssertFalse(self.mediaPlayerController.live);
}

- (void)testLiveProperties
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeLive);
    XCTAssertTrue(self.mediaPlayerController.live);
}

- (void)testDVRProperties
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeDVR);
    XCTAssertTrue(self.mediaPlayerController.live);
    
    // Seek 10 seconds in the past. The default live tolerance is 30 seconds, we still must be in live conditions
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(10., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertTrue(self.mediaPlayerController.live);
    
    // Seek 40 seconds in the past. We now are outside the tolerance and therefore not live anymore
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(40., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertFalse(self.mediaPlayerController.live);
}

- (void)testLiveTolerance
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.liveTolerance = 50.;
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeDVR);
    XCTAssertTrue(self.mediaPlayerController.live);
    
    // Seek 40 seconds in the past. The live tolerance has been set to 50 seconds, we still must be live
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(10., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertTrue(self.mediaPlayerController.live);
    
    // Seek 60 seconds in the past. We now are outside the tolerance and therefore not live anymore
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(60., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertFalse(self.mediaPlayerController.live);
}

- (void)testMinimumDVRWindowLength
{
    // Use an extremeley long window length to be sure it is far greater than the stream length (which could vary since
    // it is not managed by us)
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.minimumDVRWindowLength = 24. * 60. * 60.;
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeLive);
    XCTAssertTrue(self.mediaPlayerController.live);
}

- (void)testPlayWithHTTP403Error
{
    [self expectationForNotification:SRGMediaPlayerPlaybackDidFailNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        NSError *error = notification.userInfo[SRGMediaPlayerErrorKey];
        XCTAssertEqualObjects(error.domain, SRGMediaPlayerErrorDomain);
        XCTAssertEqual(error.code, SRGMediaPlayerErrorPlayback);
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
  
    [self.mediaPlayerController playURL:[NSURL URLWithString:@"http://httpbin.org/status/403"]];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPrepareWithHTTP404Error
{
    [self expectationForNotification:SRGMediaPlayerPlaybackDidFailNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        NSError *error = notification.userInfo[SRGMediaPlayerErrorKey];
        XCTAssertEqualObjects(error.domain, SRGMediaPlayerErrorDomain);
        XCTAssertEqual(error.code, SRGMediaPlayerErrorPlayback);
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"http://httpbin.org/status/404"];
    [self.mediaPlayerController prepareToPlayURL:URL atTime:kCMTimeZero withSegments:nil userInfo:nil completionHandler:^{
        XCTFail(@"The completion handler must not be called when the media could not be loaded");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekWhilePaused
{
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the paused state to seek
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStatePaused) {
            return NO;
        }
        
        [self.mediaPlayerController seekToTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
            // No seek could have interrupted this one
            XCTAssertTrue(finished);
            
            // The player must still be paused after the seek
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
            
            [seekFinishedExpectation fulfill];
        }];
        
        return YES;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekWhilePlaying
{
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the playing state to seek
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStatePlaying) {
            return NO;
        }
        
        [self.mediaPlayerController seekToTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
            // No seek could have interrupted this one
            XCTAssertTrue(finished);
            
            // The player must still be playing after the seek
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
            
            [seekFinishedExpectation fulfill];
        }];
        
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekNotification
{
    // Wait until the player is in the playing state to seek
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    CMTime time = CMTimeMakeWithSeconds(30., NSEC_PER_SEC);
    
    [self expectationForNotification:SRGMediaPlayerSeekNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateSeeking);
        XCTAssertTrue(CMTIME_COMPARE_INLINE([notification.userInfo[SRGMediaPlayerSeekTimeKey] CMTimeValue], ==, time));
        return YES;
    }];
    
    [self.mediaPlayerController seekToTime:time withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekWithoutPrepare
{
    [self.mediaPlayerController seekToTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
        XCTFail(@"The completion handler must not be called since a seek must do nothing if the media was not prepared");
    }];
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
}

- (void)testSeekInterruption
{
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the playing state to seek
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStatePlaying) {
            return NO;
        }
        
        [self.mediaPlayerController seekToTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
            // This seek must have been interrupted by the second one
            XCTAssertFalse(finished);
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateSeeking);
        }];
        [self.mediaPlayerController seekToTime:CMTimeMakeWithSeconds(50., NSEC_PER_SEC) withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
            XCTAssertTrue(finished);
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
            
            [seekFinishedExpectation fulfill];
        }];
        
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSharpSeekInterruption
{
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the playing state to seek
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStatePlaying) {
            return NO;
        }
        
        [self.mediaPlayerController seekToTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withToleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            // This seek must have been interrupted by the second one
            XCTAssertFalse(finished);
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateSeeking);
        }];
        [self.mediaPlayerController seekToTime:CMTimeMakeWithSeconds(50., NSEC_PER_SEC) withToleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            XCTAssertTrue(finished);
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
            
            [seekFinishedExpectation fulfill];
        }];
        
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekInterruptionSeries
{
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the playing state to seek
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStatePlaying) {
            return NO;
        }
        
        static const NSInteger kSeekCount = 100;
        
        __block NSInteger finishedSeekCount = 0;
        for (NSInteger i = 0; i < kSeekCount; ++i) {
            [self.mediaPlayerController seekToTime:CMTimeMakeWithSeconds(10. + i * 5., NSEC_PER_SEC) withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
                finishedSeekCount++;
                
                if (i != kSeekCount - 1) {
                    XCTAssertFalse(finished);
                }
                else {
                    XCTAssertTrue(finished);
                    XCTAssertEqual(finishedSeekCount, kSeekCount);
                    [seekFinishedExpectation fulfill];
                }
            }];
        }
        
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testReset
{
    // Wait until playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Pass empty collections as parameters
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[] userInfo:@{}];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Reset the player and check its status
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        
        XCTAssertNil(self.mediaPlayerController.contentURL);
        XCTAssertNil(self.mediaPlayerController.segments);
        XCTAssertNil(self.mediaPlayerController.userInfo);
        
        // Receive previous playback information since it has changed
        XCTAssertNotNil(notification.userInfo[SRGMediaPlayerPreviousContentURLKey]);
        XCTAssertNotNil(notification.userInfo[SRGMediaPlayerPreviousUserInfoKey]);
        
        return YES;
    }];
    
    XCTAssertNotNil(self.mediaPlayerController.contentURL);
    XCTAssertNotNil(self.mediaPlayerController.segments);
    XCTAssertNotNil(self.mediaPlayerController.userInfo);
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testStop
{
    // Wait until playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Pass empty collections as parameters
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:@[] userInfo:@{}];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Stop the player and check its status
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        
        XCTAssertNotNil(self.mediaPlayerController.contentURL);
        XCTAssertNotNil(self.mediaPlayerController.segments);
        XCTAssertNotNil(self.mediaPlayerController.userInfo);
        
        // No previous playback information since it has not changed
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousContentURLKey]);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousUserInfoKey]);
        
        return YES;
    }];
    
    XCTAssertNotNil(self.mediaPlayerController.contentURL);
    XCTAssertNotNil(self.mediaPlayerController.segments);
    XCTAssertNotNil(self.mediaPlayerController.userInfo);
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testConsecutiveMediaPlaybackInSamePlayer
{
    // Wait until playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDictionary *userInfo = @{ @"test_key" : @"test_value" };
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:userInfo];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Wait until playing again. Expect a playback state change to idle, then to play
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStateIdle) {
            return NO;
        }
        
        // Expect previous playback information since it has changed
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousContentURLKey], OnDemandTestURL());
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousUserInfoKey], userInfo);
        
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayerLifecycle
{
    // Wait until playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTestExpectation *creationExpectation = [self expectationWithDescription:@"Player created"];
    self.mediaPlayerController.playerCreationBlock = ^(AVPlayer *player) {
        [creationExpectation fulfill];
    };
    
    XCTestExpectation *configurationReloadExpectation = [self expectationWithDescription:@"Configuration reloaded"];
    self.mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
        [configurationReloadExpectation fulfill];
    };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Reset the player
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    XCTestExpectation *destructionExpectation = [self expectationWithDescription:@"Player destroyed"];
    self.mediaPlayerController.playerDestructionBlock = ^{
        [destructionExpectation fulfill];
    };
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testConfigurationReload
{
    // Wait until playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTestExpectation *creationExpectation = [self expectationWithDescription:@"Player created"];
    self.mediaPlayerController.playerCreationBlock = ^(AVPlayer *player) {
        [creationExpectation fulfill];
    };
    
    XCTestExpectation *configurationInitialReloadExpectation = [self expectationWithDescription:@"Configuration initially reloaded"];
    self.mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
        [configurationInitialReloadExpectation fulfill];
    };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Reload the configuration
    XCTestExpectation *configurationReloadExpectation = [self expectationWithDescription:@"Configuration reloaded"];
    self.mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
        [configurationReloadExpectation fulfill];
    };
    
    [self.mediaPlayerController reloadPlayerConfiguration];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testConfigurationReloadBeforePlayerIsAvailable
{
    __weak __typeof(self) weakSelf = self;
    self.mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
        _XCTPrimitiveFail(weakSelf, @"Player configuration must not be called if no player is available");
    };
    
    [self.mediaPlayerController reloadPlayerConfiguration];
}

- (void)testStateChangeNotificationContent
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaybackStateKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@"playbackState" expectedValue:@(SRGMediaPlayerPlaybackStatePreparing)];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testStalled
{
    // Idea (might take some time to implement, later): We could expose the resourceLoader property of the AVURLAsset we
    // can additionally create when instantiating the AVPlayer. Using AVAssetResourceLoader, it is possible to load
    // data in a custom way (in our case, to simulate a slow network). Custom URL protocols cannot be used with AVPlayer
}

- (void)testPeriodicTimeObserver
{
    XCTestExpectation *observerExpectation = [self expectationWithDescription:@"Periodic time observer fired"];
    
    __weak __typeof(self) weakSelf = self;
    __block id periodicTimeObserver = [self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        [observerExpectation fulfill];
        
        // Do not fulfill the expectation more than once
        [weakSelf.mediaPlayerController removePeriodicTimeObserver:periodicTimeObserver];
    }];
    
    // Periodic time observers fire only when the player has been created
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

@end
