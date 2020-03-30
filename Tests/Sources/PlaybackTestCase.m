//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"
#import "TestMacros.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

static NSURL *ShortNonStreamedTestURL(void)
{
    return [NSURL URLWithString:@"http://techslides.com/demos/sample-videos/small.mp4"];
}

static NSURL *LiveTestURL(void)
{
    return [NSURL URLWithString:@"http://tagesschau-lh.akamaihd.net/i/tagesschau_1@119231/master.m3u8?dw=0"];
}

static NSURL *DVRTestURL(void)
{
    return [NSURL URLWithString:@"http://tagesschau-lh.akamaihd.net/i/tagesschau_1@119231/master.m3u8"];
}

static NSURL *DVRTimestampTestURL(void)
{
    return [NSURL URLWithString:@"https://mcdn.daserste.de/daserste/int/master.m3u8"];
}

static NSURL *AudioOverHTTPTestURL(void)
{
    return [NSURL URLWithString:@"https://rtsww-a-d.rts.ch/la-1ere/programmes/c-est-pas-trop-tot/2017/c-est-pas-trop-tot_20170628_full_c-est-pas-trop-tot_007d77e7-61fb-4aef-9491-5e6b07f7f931-128k.mp3"];
}

@interface PlaybackTestCase : MediaPlayerBaseTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation PlaybackTestCase

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

- (void)testDeallocationWhileIdle
{
    __weak SRGMediaPlayerController *weakMediaPlayerController = self.mediaPlayerController;
    
    @autoreleasepool {
        self.mediaPlayerController = nil;
    }
    
    XCTAssertNil(weakMediaPlayerController);
}

- (void)testDeallocationAfterPlayback
{
    __weak SRGMediaPlayerController *weakMediaPlayerController = self.mediaPlayerController;
    __weak AVPlayer *weakPlayer = self.mediaPlayerController.player;
    
    @autoreleasepool {
        [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
        }];
        
        [self.mediaPlayerController playURL:OnDemandTestURL()];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
        
        [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
        }];
        
        // Ensure the player is correctly deallocated
        [self expectationForPredicate:[NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return weakPlayer == nil;
        }] evaluatedWithObject:self /* unused, but a non-nil argument is required  */ handler:nil];
        
        [self.mediaPlayerController reset];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
        
        self.mediaPlayerController = nil;
    }
    
    XCTAssertNil(weakMediaPlayerController);
}

- (void)testInitialPlayerState
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
    TestAssertIndefiniteTime(mediaPlayerController.seekStartTime);
    TestAssertIndefiniteTime(mediaPlayerController.seekTargetTime);
}

- (void)testPrepareWithURL
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil completionHandler:^{
        // Upon completion handler entry, the state is always preparing
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    }];
    
    XCTAssertEqualObjects(self.mediaPlayerController.contentURL, OnDemandTestURL());
    XCTAssertNotNil(self.mediaPlayerController.URLAsset);
    
    TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
    TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // After completion handler execution, the player state is updated. Since nothing is done in the completion handler,
    // the player must be paused
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        // Check the next notification
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPrepareWithAsset
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    AVURLAsset *URLAsset = [AVURLAsset assetWithURL:OnDemandTestURL()];
    [self.mediaPlayerController prepareToPlayURLAsset:URLAsset atPosition:nil withSegments:nil userInfo:nil completionHandler:^{
        // Upon completion handler entry, the state is always preparing
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    }];
    
    XCTAssertEqualObjects(self.mediaPlayerController.contentURL, OnDemandTestURL());
    XCTAssertEqualObjects(self.mediaPlayerController.URLAsset, URLAsset);
    
    TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
    TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // After completion handler execution, the player state is updated. Since nothing is done in the completion handler,
    // the player must be paused
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
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
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil completionHandler:^{
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
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil completionHandler:^{
        XCTFail(@"The completion handler must not be called since a second prepare must cancel the first");
    }];
    
    XCTestExpectation *preparationExpectation = [self expectationWithDescription:@"Prepared"];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil completionHandler:^{
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

- (void)testPlay
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        // The player must have transitioned directly to the playing state without going through the paused state
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testOnDemandPlaybackStartAtTime
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:20.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Check we started at the specified location
    XCTAssertTrue(CMTIME_COMPARE_INLINE(self.mediaPlayerController.currentTime, ==, CMTimeMakeWithSeconds(20., NSEC_PER_SEC)));
}

- (void)testOnDemandPlaybackStartAtDate
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtDate:NSDate.date] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Ignored for on-demand streams. Start at the beginning
    XCTAssertTrue(CMTIME_COMPARE_INLINE(self.mediaPlayerController.currentTime, <, CMTimeMakeWithSeconds(1., NSEC_PER_SEC)));
}

- (void)testDVRPlaybackDefaultStart
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Check we started near the end
    XCTAssertTrue(CMTIME_COMPARE_INLINE(self.mediaPlayerController.currentTime, >, CMTimeSubtract(self.mediaPlayerController.currentTime, CMTimeMakeWithSeconds(60., NSEC_PER_SEC))));
}

- (void)testDVRPlaybackStartAtTime
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:20.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Check we started at the specified location
    XCTAssertTrue(CMTIME_COMPARE_INLINE(self.mediaPlayerController.currentTime, ==, CMTimeMakeWithSeconds(20., NSEC_PER_SEC)));
}

- (void)testDVRPlaybackStartAtDateWithoutTimestamps
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-10. * 60.];
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:[SRGPosition positionAtDate:date] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Check we started at the specified location (strict check on time, loose check on date)
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)) - 10. * 60., 5.);
    TestAssertAlmostEqualDate(self.mediaPlayerController.currentDate, date, 50.);
}

- (void)testDVRPlaybackStartAtDateWithTimestamps
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-10. * 60.];
    [self.mediaPlayerController playURL:DVRTimestampTestURL() atPosition:[SRGPosition positionAtDate:date] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Check we started at the specified location (strict check on date, loose check on time)
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)) - 10. * 60., 50.);
    TestAssertAlmostEqualDate(self.mediaPlayerController.currentDate, date, 1.);
}

- (void)testOnDemandPlaybackStartAtTimeWithTolerances
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAroundTimeInSeconds:22.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Check we started near the specified location
    TestAssertAlmostButNotEqual(self.mediaPlayerController.currentTime, 22, 4);
}

- (void)testPlayAtTimeBeforeOnDemandMediaStart
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                             atPosition:[SRGPosition positionAtTimeInSeconds:-24. * 60. * 60.]
                           withSegments:nil
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Start at the default position (media start)
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 0., 5.);
}

- (void)testPlayAtTimeAfterOnDemandMediaEnd
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                             atPosition:[SRGPosition positionAtTimeInSeconds:24. * 60. * 60.]
                           withSegments:nil
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Start at the default position (media start)
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 0., 5.);
}

- (void)testPlayAtTimeBeforeDVRStreamStart
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTimestampTestURL()
                             atPosition:[SRGPosition positionAtTimeInSeconds:-24. * 60. * 60.]
                           withSegments:nil
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Start at the default position (live conditions)
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)), 5.);
}

- (void)testPlayAtTimeAfterDVRStreamEnd
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTimestampTestURL()
                             atPosition:[SRGPosition positionAtTimeInSeconds:24. * 60. * 60.]
                           withSegments:nil
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Start at the default position (live conditions)
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)), 5.);
}

- (void)testPlayAtDateBeforeDVRStreamStart
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0.];
    [self.mediaPlayerController playURL:DVRTimestampTestURL()
                             atPosition:[SRGPosition positionAtDate:date]
                           withSegments:nil
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Start at the default position (live conditions)
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)), 5.);
}

- (void)testPlayAtDateAfterDVRStreamEnd
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-24. * 60. * 60.];
    [self.mediaPlayerController playURL:DVRTimestampTestURL()
                             atPosition:[SRGPosition positionAtDate:date]
                           withSegments:nil
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Start at the default position (live conditions)
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)), 5.);
}

- (void)testPlayAtTimeWithLivestream
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()
                             atPosition:[SRGPosition positionAtTimeInSeconds:24. * 60. * 60.]
                           withSegments:nil
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)), 5.);
}

- (void)testPlayAtDateWithLivestream
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:24. * 60. * 60.];
    [self.mediaPlayerController playURL:LiveTestURL()
                             atPosition:[SRGPosition positionAtDate:date]
                           withSegments:nil
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)), 5.);
}

- (void)testVideoTrackInLastPosition
{
    // The video track is not always located first in the tracks list.
    [self expectationForPredicate:[NSPredicate predicateWithBlock:^BOOL(SRGMediaPlayerController * _Nullable mediaPlayerController, NSDictionary<NSString *,id> * _Nullable bindings) {
        return mediaPlayerController.mediaType != SRGMediaPlayerMediaTypeUnknown;
    }] evaluatedWithObject:self.mediaPlayerController handler:nil];
    
    [self.mediaPlayerController playURL:[NSURL URLWithString:@"http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v"]];
    
    [self waitForExpectationsWithTimeout:40. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaType, SRGMediaPlayerMediaTypeVideo);
}

- (void)testLiveAACPlayback
{
    [self expectationForPredicate:[NSPredicate predicateWithBlock:^BOOL(SRGMediaPlayerController * _Nullable mediaPlayerController, NSDictionary<NSString *,id> * _Nullable bindings) {
        return mediaPlayerController.streamType != SRGMediaPlayerStreamTypeUnknown;
    }] evaluatedWithObject:self.mediaPlayerController handler:nil];
    
    [self.mediaPlayerController playURL:[NSURL URLWithString:@"http://stream.srg-ssr.ch/m/la-1ere/aacp_96"]];
    
    [self waitForExpectationsWithTimeout:40. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeLive);
}

- (void)testHTTPAudioPlay
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:AudioOverHTTPTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
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
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ++count1;
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
    
    // Two events expected: preparing and playing
    XCTAssertEqual(count1, 2);
    
    __block NSInteger count2 = 0;
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ++count2;
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
    
    // One event expected: paused
    XCTAssertEqual(count2, 1);
    
    __block NSInteger count3 = 0;
    id eventObserver3 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ++count3;
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver3];
    }];
    
    // One event expected: playing
    XCTAssertEqual(count3, 1);
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver4 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver4];
    }];
}

- (void)testFastPlaySeek
{
    // Play the media. Two events expected: Preparing and playing
    __block NSInteger count1 = 0;
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ++count1;
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying) {
            TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 0);
            return YES;
        }
        else {
            return NO;
        }
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
    
    TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
    TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
    
    // Two events expected: preparing and playing
    XCTAssertEqual(count1, 2);
    
    __block NSInteger count2 = 0;
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ++count2;
    }];
    
    __block BOOL seekReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(playReceived);
            TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 0);
            seekReceived = YES;
        }
        else if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying) {
            XCTAssertFalse(playReceived);
            TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 2);
            playReceived = YES;
        }
        
        return seekReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:2.] withCompletionHandler:nil];
    
    TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekStartTime, 0);
    TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekTargetTime, 2);
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
    
    TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
    TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
    
    // Two events expected: seek and play
    XCTAssertEqual(count2, 2);
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver3 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver3];
    }];
}

- (void)testFastPlayPauseSeek
{
    // Play the media. Two events expected: Preparing and playing
    __block NSInteger count1 = 0;
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ++count1;
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying) {
            TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 0);
            return YES;
        }
        else {
            return NO;
        }
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
    
    TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
    TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
    
    // Two events expected: preparing and playing
    XCTAssertEqual(count1, 2);
    
    __block NSInteger count2 = 0;
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ++count2;
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
    
    TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
    TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
    
    // One event expected: paused
    XCTAssertEqual(count2, 1);
    
    __block NSInteger count3 = 0;
    id eventObserver3 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ++count3;
    }];
    
    __block BOOL seekReceived = NO;
    __block BOOL pauseReceived = NO;
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGMediaPlayerPlaybackState playerPlaybackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
        if (playerPlaybackState == SRGMediaPlayerPlaybackStateSeeking) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(pauseReceived);
            TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 0);
            seekReceived = YES;
        }
        else if (playerPlaybackState == SRGMediaPlayerPlaybackStatePaused) {
            XCTAssertFalse(pauseReceived);
            TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, 2);
            pauseReceived = YES;
        }
        else {
            XCTFail(@"Unexpected playback state %@", @(playerPlaybackState));
        }
        
        return seekReceived && pauseReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:2.] withCompletionHandler:nil];
    
    TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekStartTime, 0);
    TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekTargetTime, 2);
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver3];
    }];
    
    TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
    TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
    
    // Two events expected: seek and pause
    XCTAssertEqual(count3, 2);
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver4 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver4];
    }];
}

- (void)testStreamedMediaPlaythrough
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Seek to the end (media is too long to be entirely played through :) )
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGPosition *position = [SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController seekToPosition:position withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateEnded);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testNonStreamedMediaPlaythrough
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:ShortNonStreamedTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
        
        // Playback is more likely to stall when playing this media. Ignore such events
        if (playbackState == SRGMediaPlayerPlaybackStateStalled) {
            return NO;
        }
        
        XCTAssertEqual(playbackState, SRGMediaPlayerPlaybackStateEnded);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayAtStreamEnd
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Seek to the end (media is too long to be entirely played through :) ) and wait until playback ends
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAroundTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Play at the end. Expect restart at the beginning of the stream with no seek events
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateEnded);
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPauseAtStreamEnd
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Seek to the end (media is too long to be entirely played through :) ) and wait until playback ends
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAroundTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Pausing when the stream already ended must be a no-op");
    }];
    
    // Pause at the end. Nothing must happen, the player has already a rate of 0
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testFixedStreamEndWithBuggyAkamaiStreamWithSubtitles
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"de");
        return YES;
    }];
    
    self.mediaPlayerController.subtitleConfigurationBlock = ^AVMediaSelectionOption * _Nullable(NSArray<AVMediaSelectionOption *> * _Nonnull subtitleOptions, AVMediaSelectionOption * _Nullable audioOption, AVMediaSelectionOption * _Nullable defaultSubtitleOption) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:@"de"];
        }];
        return [subtitleOptions filteredArrayUsingPredicate:predicate].firstObject ?: defaultSubtitleOption;
    };
    
    NSURL *URL = [NSURL URLWithString:@"https://srfvodhd-vh.akamaihd.net/i/vod/10vor10/2020/03/10vor10_20200326_215000_20178198_v_webcast_h264_,q40,q10,q20,q30,q50,q60,.mp4.csmil/master.m3u8?start=0.0&end=1705.64&caption=srf/af5c0281-9070-43c4-a00d-542c7d5b007d/episode/de/vod/vod.m3u8:de:Deutsch:sdh&webvttbaseurl=www.srf.ch/subtitles"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Seek to the end (media is too long to be entirely played through :) ) and wait until playback ends
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAroundTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLivePause
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaTypeTransitionDuringPreparation
{
    XCTAssertEqual(self.mediaPlayerController.mediaType, SRGMediaPlayerMediaTypeUnknown);
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, mediaType) expectedValue:nil];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaType, SRGMediaPlayerMediaTypeVideo);
}

- (void)testMediaInformationWhenPreparingToPlay
{
    XCTAssertEqual(self.mediaPlayerController.mediaType, SRGMediaPlayerMediaTypeUnknown);
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeUnknown);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertEqual(self.mediaPlayerController.mediaType, SRGMediaPlayerMediaTypeUnknown);
        XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeUnknown);
        return YES;
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prepared"];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil completionHandler:^{
        XCTAssertEqual(self.mediaPlayerController.mediaType, SRGMediaPlayerMediaTypeVideo);
        XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeOnDemand);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testOnDemandProperties
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeOnDemand);
    XCTAssertFalse(self.mediaPlayerController.live);
    XCTAssertNil(self.mediaPlayerController.currentDate);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeUnknown);
    XCTAssertFalse(self.mediaPlayerController.live);
    XCTAssertNil(self.mediaPlayerController.currentDate);
}

- (void)testLiveProperties
{
    // FIXME: See https://github.com/SRGSSR/SRGMediaPlayer-iOS/issues/50. Workaround so that the test passes on iOS >= 11.3.
    NSOperatingSystemVersion operatingSystemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
    if (operatingSystemVersion.majorVersion == 11 && operatingSystemVersion.minorVersion >= 3) {
        self.mediaPlayerController.minimumDVRWindowLength = 40.;
    }
    
    [self expectationForPredicate:[NSPredicate predicateWithBlock:^BOOL(SRGMediaPlayerController * _Nullable mediaPlayerController, NSDictionary<NSString *,id> * _Nullable bindings) {
        return mediaPlayerController.streamType != SRGMediaPlayerStreamTypeUnknown;
    }] evaluatedWithObject:self.mediaPlayerController handler:nil];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeLive);
    XCTAssertTrue(self.mediaPlayerController.live);
    XCTAssertTrue([NSDate.date timeIntervalSinceDate:self.mediaPlayerController.currentDate] < 0.1);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeUnknown);
    XCTAssertFalse(self.mediaPlayerController.live);
    XCTAssertNil(self.mediaPlayerController.currentDate);
}

- (void)testDVRProperties
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeDVR);
    XCTAssertTrue(self.mediaPlayerController.live);
    XCTAssertNotNil(self.mediaPlayerController.currentDate);
    
    // Seek 10 seconds in the past. The default live tolerance is 30 seconds, we still must be in live conditions
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertTrue(self.mediaPlayerController.live);
    XCTAssertTrue([NSDate.date timeIntervalSinceDate:self.mediaPlayerController.currentDate] > 8);
    
    // Seek 40 seconds in the past. We now are outside the tolerance and therefore not live anymore
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(40., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertFalse(self.mediaPlayerController.live);
    XCTAssertTrue([NSDate.date timeIntervalSinceDate:self.mediaPlayerController.currentDate] > 38);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeUnknown);
    XCTAssertFalse(self.mediaPlayerController.live);
    XCTAssertNil(self.mediaPlayerController.currentDate);
}

- (void)testLiveTolerance
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.liveTolerance = 50.;
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGMediaPlayerStreamTypeDVR);
    XCTAssertTrue(self.mediaPlayerController.live);
    
    // Seek 40 seconds in the past. The live tolerance has been set to 50 seconds, we still must be live
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertTrue(self.mediaPlayerController.live);
    
    // Seek 60 seconds in the past. We now are outside the tolerance and therefore not live anymore
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(60., NSEC_PER_SEC))] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertFalse(self.mediaPlayerController.live);
}

- (void)testMinimumDVRWindowLength
{
    // Use an extremeley long window length to be sure it is far greater than the stream length (which could vary since
    // it is not managed by us)
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
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
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackDidFailNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
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
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackDidFailNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        NSError *error = notification.userInfo[SRGMediaPlayerErrorKey];
        XCTAssertEqualObjects(error.domain, SRGMediaPlayerErrorDomain);
        XCTAssertEqual(error.code, SRGMediaPlayerErrorPlayback);
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"http://httpbin.org/status/404"];
    [self.mediaPlayerController prepareToPlayURL:URL atPosition:nil withSegments:nil userInfo:nil completionHandler:^{
        XCTFail(@"The completion handler must not be called when the media could not be loaded");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekWhilePaused
{
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the paused state to seek
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStatePaused) {
            return NO;
        }
        
        TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
        TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
        
        [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:30.] withCompletionHandler:^(BOOL finished) {
            // No seek could have interrupted this one
            XCTAssertTrue(finished);
            
            // The player must still be paused after the seek
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
            
            TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
            TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
            [seekFinishedExpectation fulfill];
        }];
        
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekStartTime, 2);
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekTargetTime, 30);
        return YES;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:2.] withSegments:nil userInfo:nil completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekWhilePlaying
{
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the playing state to seek
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStatePlaying) {
            return NO;
        }
        
        TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
        TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
        
        [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:30.] withCompletionHandler:^(BOOL finished) {
            // No seek could have interrupted this one
            XCTAssertTrue(finished);
            
            // The player must still be playing after the seek
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
            
            TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
            TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
            [seekFinishedExpectation fulfill];
        }];
        
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekStartTime, 2);
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekTargetTime, 30);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:2.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekNotification
{
    // Wait until the player is in the playing state to seek
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSeekNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateSeeking);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerSeekTimeKey] CMTimeValue], 30);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:30.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekWithoutPrepare
{
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:30.] withCompletionHandler:^(BOOL finished) {
        XCTFail(@"The completion handler must not be called since a seek must do nothing if the media was not prepared");
    }];
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
    TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
    TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
}

- (void)testSeekInterruption
{
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the playing state to seek
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStatePlaying) {
            return NO;
        }
        
        TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
        TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
        
        [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:30.] withCompletionHandler:^(BOOL finished) {
            // This seek must have been interrupted by the second one
            XCTAssertFalse(finished);
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateSeeking);
            
            TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekStartTime, 2);
            TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekTargetTime, 50);
        }];
        [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:50.] withCompletionHandler:^(BOOL finished) {
            XCTAssertTrue(finished);
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
            TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
            TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
            
            [seekFinishedExpectation fulfill];
        }];
        
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekStartTime, 2);
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekTargetTime, 50);
        
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:2.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSharpSeekInterruption
{
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the playing state to seek
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStatePlaying) {
            return NO;
        }
        
        TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
        TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
        
        [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:30.] withCompletionHandler:^(BOOL finished) {
            // This seek must have been interrupted by the second one
            XCTAssertFalse(finished);
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateSeeking);
            
            TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekStartTime, 2);
            TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekTargetTime, 50);
        }];
        [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:50.] withCompletionHandler:^(BOOL finished) {
            XCTAssertTrue(finished);
            XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
            TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
            TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
            
            [seekFinishedExpectation fulfill];
        }];
        
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekStartTime, 2);
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekTargetTime, 50);
        
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:2.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekInterruptionSeries
{
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the playing state to seek
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStatePlaying) {
            return NO;
        }
        
        static const NSInteger kSeekCount = 100;
        
        __block NSInteger finishedSeekCount = 0;
        for (NSInteger i = 0; i < kSeekCount; ++i) {
            [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:10. + i * 5.] withCompletionHandler:^(BOOL finished) {
                finishedSeekCount++;
                
                if (i != kSeekCount - 1) {
                    XCTAssertFalse(finished);
                    
                    // The start time must remain constant while seeks are piling up. The end time changes and is therefore
                    // difficult to test reliably when several seeks are interrupted.
                    TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekStartTime, 0);
                }
                else {
                    XCTAssertTrue(finished);
                    XCTAssertEqual(finishedSeekCount, kSeekCount);
                    TestAssertIndefiniteTime(self.mediaPlayerController.seekStartTime);
                    TestAssertIndefiniteTime(self.mediaPlayerController.seekTargetTime);
                    [seekFinishedExpectation fulfill];
                }
            }];
        }
        
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekStartTime, 0);
        TestAssertEqualTimeInSeconds(self.mediaPlayerController.seekTargetTime, 10. + (kSeekCount - 1) * 5.);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaySeekAndPlayWhileSeeking
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:10.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaySeekAndPauseWhileSeeking
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:10.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self.mediaPlayerController pause];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPauseSeekAndPlayWhileSeeking
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:10.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPauseSeekAndPauseWhileSeeking
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:10.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaySeekAndTogglePlayPauseWhileSeeking
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:10.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        return YES;
    }];
    
    [self.mediaPlayerController togglePlayPause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPauseSeekAndTogglePlayPauseWhileSeeking
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:10.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePlaying);
        return YES;
    }];
    
    [self.mediaPlayerController togglePlayPause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testDVRSeeks
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertEqualTimeInSeconds(self.mediaPlayerController.timeRange.start, 0.);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Seek to a past position relative to the current position
    CMTime initialTime = self.mediaPlayerController.currentTime;
    CMTime targetTime1 = CMTimeSubtract(initialTime, CMTimeMakeWithSeconds(400., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:targetTime1] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(targetTime1), 1.);
    TestAssertEqualTimeInSeconds(self.mediaPlayerController.timeRange.start, 0.);
    
    // The stream chunk size is 10 seconds and the stream window is sliding. Play a little bit longer than the chunk size
    // so that a new chunk is pumped in at the end (and a chunk pumped out at the beginning).
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Seek forward relative to the current position
    CMTime targetTime2 = CMTimeAdd(self.mediaPlayerController.currentTime, CMTimeMakeWithSeconds(10., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:targetTime2] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertEqualTimeInSeconds(self.mediaPlayerController.currentTime, CMTimeGetSeconds(targetTime2));
    TestAssertNotEqualTimeInSeconds(self.mediaPlayerController.timeRange.start, 0.);
}

- (void)testDVRSeekToDate
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTimestampTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertEqualTimeInSeconds(self.mediaPlayerController.timeRange.start, 0.);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Seek to a past position relative to the current date
    NSDate *initialDate = self.mediaPlayerController.currentDate;
    NSDate *targetDate = [initialDate dateByAddingTimeInterval:-400.];
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtDate:targetDate] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqualDate(self.mediaPlayerController.currentDate, targetDate, 1.);
    TestAssertEqualTimeInSeconds(self.mediaPlayerController.timeRange.start, 0.);
}

- (void)testOnDemandSeekToDate
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Seek to date not supported, replace with default position
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtDate:NSDate.date] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 0., 1.);
    XCTAssertNil(self.mediaPlayerController.currentDate);
}

- (void)testSeekToTimeBeforeOnDemandStreamStart
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:200.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:-100.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 0., 1.);
}

- (void)testSeekToTimeAfterOnDemandStreamEnd
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:200.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:24. * 60. * 60.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)), 1.);
}

- (void)testSeekToTimeBeforeDVRStreamStart
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:200.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:-100.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 0., 5.);
}

- (void)testSeekToTimeAfterDVRStreamEnd
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:200.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:24. * 60. * 60.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)), 5.);
}

- (void)testSeekToDateBeforeDVRStreamStart
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:200.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0.];
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtDate:date] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 0., 5.);
}

- (void)testSeekToDateAfterDVRStreamEnd
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:200.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:24. * 60. * 60.];
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtDate:date] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, CMTimeGetSeconds(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)), 5.);
}

- (void)testSeekToTimeWithLivestream
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id seekObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTAssertNotEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateSeeking);
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:100.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:seekObserver];
    }];
}

- (void)testSeekToDateWithLivestream
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id seekObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTAssertNotEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateSeeking);
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:24. * 60. * 60.];
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtDate:date] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:seekObserver];
    }];
}

- (void)testNoStallsDuringNormalOnDemandPlayback
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    id stallObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTAssertNotEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateStalled);
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:stallObserver];
    }];
}

- (void)testNoStallsDuringNormalLivestreamPlayback
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    id stallObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTAssertNotEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateStalled);
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:stallObserver];
    }];
}

- (void)testNoStallsDuringNormalDVRPlayback
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    id stallObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTAssertNotEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateStalled);
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:stallObserver];
    }];
}

- (void)testReset
{
    @autoreleasepool {
        [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
        }];
        
        // Pass empty collections as parameters
        [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:2.] withSegments:@[] userInfo:@{}];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
        
        // Ensure the player is correctly deallocated
        __weak AVPlayer *weakPlayer = self.mediaPlayerController.player;
        [self expectationForPredicate:[NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return weakPlayer == nil;
        }] evaluatedWithObject:self /* unused, but a non-nil argument is required */ handler:nil];
        
        // Reset the player and check its status
        [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
            XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
            
            XCTAssertNil(self.mediaPlayerController.contentURL);
            XCTAssertNil(self.mediaPlayerController.URLAsset);
            XCTAssertNil(self.mediaPlayerController.segments);
            XCTAssertNil(self.mediaPlayerController.userInfo);
            
            // Receive previous playback information since it has changed
            XCTAssertNotNil(notification.userInfo[SRGMediaPlayerPreviousContentURLKey]);
            XCTAssertNotNil(notification.userInfo[SRGMediaPlayerPreviousURLAssetKey]);
            XCTAssertNotNil(notification.userInfo[SRGMediaPlayerPreviousTimeRangeKey]);
            XCTAssertNotNil(notification.userInfo[SRGMediaPlayerPreviousMediaTypeKey]);
            XCTAssertNotNil(notification.userInfo[SRGMediaPlayerPreviousStreamTypeKey]);
            XCTAssertNotNil(notification.userInfo[SRGMediaPlayerPreviousUserInfoKey]);
            XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSelectedSegmentKey]);
            
            TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 2);
            return YES;
        }];
        
        XCTAssertNotNil(self.mediaPlayerController.contentURL);
        XCTAssertNotNil(self.mediaPlayerController.URLAsset);
        XCTAssertNotNil(self.mediaPlayerController.segments);
        XCTAssertNotNil(self.mediaPlayerController.userInfo);
        
        [self.mediaPlayerController reset];
    }
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testResetWhilePreparing
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:^{
        XCTFail(@"Must not be called");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testResetWhileSeeking
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:10.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testStop
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Pass empty collections as parameters
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[] userInfo:@{}];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Stop the player and check its status
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        
        XCTAssertNotNil(self.mediaPlayerController.contentURL);
        XCTAssertNotNil(self.mediaPlayerController.URLAsset);
        XCTAssertNotNil(self.mediaPlayerController.segments);
        XCTAssertNotNil(self.mediaPlayerController.userInfo);
        
        // No previous playback information since it has not changed
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousContentURLKey]);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousURLAssetKey]);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousUserInfoKey]);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSelectedSegmentKey]);
        
        // Previous playback information since it has changed
        XCTAssertNotNil(notification.userInfo[SRGMediaPlayerPreviousMediaTypeKey]);
        XCTAssertNotNil(notification.userInfo[SRGMediaPlayerPreviousTimeRangeKey]);
        XCTAssertNotNil(notification.userInfo[SRGMediaPlayerPreviousStreamTypeKey]);
        
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue], 0);
        return YES;
    }];
    
    XCTAssertNotNil(self.mediaPlayerController.contentURL);
    XCTAssertNotNil(self.mediaPlayerController.URLAsset);
    XCTAssertNotNil(self.mediaPlayerController.segments);
    XCTAssertNotNil(self.mediaPlayerController.userInfo);
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayWhilePreparing
{
    // Wait until preparing
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGPlaybackButtonState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
        if (playbackState == SRGMediaPlayerPlaybackStatePlaying) {
            return YES;
        }
        
        if (playbackState == SRGMediaPlayerPlaybackStatePreparing) {
            [self.mediaPlayerController play];
        }
        return NO;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPauseWhilePreparing
{
    // Wait until preparing
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGPlaybackButtonState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
        if (playbackState == SRGMediaPlayerPlaybackStatePaused) {
            return YES;
        }
        
        if (playbackState == SRGMediaPlayerPlaybackStatePreparing) {
            [self.mediaPlayerController pause];
        }
        return NO;
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testStopWhileWhilePreparing
{
    // Wait until preparing
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStatePreparing) {
            return NO;
        }
        
        // Stop early when the notification is received
        [self.mediaPlayerController stop];
        return YES;
    }];
    
    // Pass empty collections as parameters
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[] userInfo:@{}];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.player);
    XCTAssertNotNil(self.mediaPlayerController.contentURL);
    XCTAssertNotNil(self.mediaPlayerController.URLAsset);
    XCTAssertNotNil(self.mediaPlayerController.segments);
    XCTAssertNotNil(self.mediaPlayerController.userInfo);
}

- (void)testStopWhileSeeking
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:10.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayAfterStopWithURL
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Stop the player and check its status
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Can be played again after a stop
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayAfterStopWithAsset
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    AVURLAsset *URLAsset = [AVURLAsset assetWithURL:OnDemandTestURL()];
    [self.mediaPlayerController playURLAsset:URLAsset atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Stop the player and check its status
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Can be played again after a stop
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayAfterReset
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Reset the player and check its status
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // The player cannot be started by simply calling -play
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player cannot be restarted with a play after a reset. No event expected");
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testOnDemandTogglePlayPause
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Toggle (pause)
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController togglePlayPause];
    
    // Toggle (play)
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController togglePlayPause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testDVRTogglePlayPause
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Toggle (pause)
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.mediaPlayerController togglePlayPause];
    
    // Toggle (play)
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController togglePlayPause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testTogglePlayPauseAfterStop
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Stop the player and check its status
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Can be played again after a stop
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController togglePlayPause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testTogglePlayPauseAfterReset
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Reset the player and check its status
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // The player cannot be started by simply calling -play
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player cannot be restarted with a togglePlayPause after a reset. No event expected");
    }];
    
    [self.mediaPlayerController togglePlayPause];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testConsecutiveMediaPlaybackInSamePlayer
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDictionary *userInfo = @{ @"test_key" : @"test_value" };
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:userInfo];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    SRGMediaPlayerMediaType mediaType = self.mediaPlayerController.mediaType;
    SRGMediaPlayerStreamType streamType = self.mediaPlayerController.streamType;
    CMTimeRange timeRange = self.mediaPlayerController.timeRange;
    NSInteger start = (NSInteger)CMTimeGetSeconds(timeRange.start);
    NSInteger duration = (NSInteger)CMTimeGetSeconds(timeRange.duration);
    
    // Wait until playing again. Expect a playback state change to idle, then to play
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] != SRGMediaPlayerPlaybackStateIdle) {
            return NO;
        }
        
        // Expect previous playback information since it has changed
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousContentURLKey], OnDemandTestURL());
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerPreviousTimeRangeKey] CMTimeRangeValue].start, start);
        TestAssertEqualTimeInSeconds([notification.userInfo[SRGMediaPlayerPreviousTimeRangeKey] CMTimeRangeValue].duration, duration);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousMediaTypeKey], @(mediaType));
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousStreamTypeKey], @(streamType));
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousUserInfoKey], userInfo);
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousSelectedSegmentKey]);
        
        return YES;
    }];
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayerLifecycle
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTestExpectation *creationExpectation = [self expectationWithDescription:@"Player created"];
    
    @weakify(self)
    self.mediaPlayerController.playerCreationBlock = ^(AVPlayer *player) {
        @strongify(self)
        XCTAssertEqual(self.mediaPlayerController.player, player);
        [creationExpectation fulfill];
    };
    
    XCTestExpectation *configurationReloadExpectation = [self expectationWithDescription:@"Configuration reloaded"];
    
    self.mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
        @strongify(self)
        XCTAssertEqual(self.mediaPlayerController.player, player);
        [configurationReloadExpectation fulfill];
    };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Reset the player
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    XCTestExpectation *destructionExpectation = [self expectationWithDescription:@"Player destroyed"];
    
    self.mediaPlayerController.playerDestructionBlock = ^(AVPlayer *player) {
        @strongify(self)
        XCTAssertEqual(self.mediaPlayerController.player, player);
        [destructionExpectation fulfill];
    };
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testConfigurationReload
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
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
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTestExpectation *configurationReloadExpectation = [self expectationWithDescription:@"Configuration reloaded"];
    self.mediaPlayerController.playerConfigurationBlock = ^(AVPlayer * _Nonnull player) {
        [configurationReloadExpectation fulfill];
    };
    [self.mediaPlayerController reloadPlayerConfiguration];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testConfigurationReloadBeforePlayerIsAvailable
{
    @weakify(self)
    self.mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
        @strongify(self)
        XCTFail(@"Player configuration must not be called if no player is available");
    };
    
    [self.mediaPlayerController reloadPlayerConfiguration];
}

- (void)testStateChangeNotificationContent
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStateIdle);
        XCTAssertFalse([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaybackStateKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, playbackState) expectedValue:@(SRGMediaPlayerPlaybackStatePreparing)];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testVideoMediaTypeKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, mediaType) expectedValue:@(SRGMediaPlayerMediaTypeVideo)];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, mediaType) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        XCTFail(@"No more media type changes should be reported");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, mediaType)];
    }];
}

- (void)testAudioMediaTypeKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, mediaType) expectedValue:@(SRGMediaPlayerMediaTypeAudio)];
    
    [self.mediaPlayerController playURL:AudioOverHTTPTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, mediaType) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        XCTFail(@"No more media type changes should be reported");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, mediaType)];
    }];
}

- (void)testOnDemandTimeRangeKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, timeRange) handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
        NSValue *timeRangeValue = change[NSKeyValueChangeNewKey];
        return SRG_CMTIMERANGE_IS_NOT_EMPTY(timeRangeValue.CMTimeRangeValue);
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, timeRange) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        XCTFail(@"For on-demand stream the time range is known once playing");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, timeRange)];
    }];
}

- (void)testLiveTimeRangeKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, timeRange) handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
        NSValue *timeRangeValue = change[NSKeyValueChangeNewKey];
        return CMTIMERANGE_IS_EMPTY(timeRangeValue.CMTimeRangeValue);
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // For livestreams we continue receiving time range updates.
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, timeRange) handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
        NSValue *timeRangeValue = change[NSKeyValueChangeNewKey];
        return CMTIMERANGE_IS_EMPTY(timeRangeValue.CMTimeRangeValue);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testDVRTimeRangeKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, timeRange) handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
        NSValue *timeRangeValue = change[NSKeyValueChangeNewKey];
        return SRG_CMTIMERANGE_IS_NOT_EMPTY(timeRangeValue.CMTimeRangeValue);
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // For livestreams we continue to receive updates.
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, timeRange) handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
        NSValue *timeRangeValue = change[NSKeyValueChangeNewKey];
        return SRG_CMTIMERANGE_IS_NOT_EMPTY(timeRangeValue.CMTimeRangeValue);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testOnDemandStreamTypeKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, streamType) expectedValue:@(SRGMediaPlayerStreamTypeOnDemand)];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, streamType) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        XCTFail(@"No more stream type changes should be reported");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, streamType)];
    }];
}

- (void)testLivestreamTypeKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, streamType) expectedValue:@(SRGMediaPlayerStreamTypeLive)];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, streamType) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        XCTFail(@"No more stream type changes should be reported");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, streamType)];
    }];
}

- (void)testDVRStreamTypeKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, streamType) expectedValue:@(SRGMediaPlayerStreamTypeDVR)];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, streamType) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        XCTFail(@"No more stream type changes should be reported");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, streamType)];
    }];
}

- (void)testOnDemandIsLiveKeyValueObserving
{
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, live) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        XCTFail(@"No more stream type changes should be reported");
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, live)];
    }];
}

- (void)testLiveIsLiveKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, live) expectedValue:@YES];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, live) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        XCTFail(@"No more live status changes should be reported");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, live)];
    }];
}

- (void)testDVRIsLiveKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, live) expectedValue:@YES];
    
    self.mediaPlayerController.liveTolerance = 15.;
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, live) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        XCTFail(@"No live status type changes should be reported");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, live)];
    }];
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, live) expectedValue:@NO];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAroundTime:self.mediaPlayerController.timeRange.start] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, live) expectedValue:@YES];
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAroundTime:CMTimeRangeGetEnd(self.mediaPlayerController.timeRange)] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, live) expectedValue:@NO];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testStalled
{
    // TODO: Idea (might take some time to implement, later): We could expose the resourceLoader property of the AVURLAsset we
    // can additionally create when instantiating the AVPlayer. Using AVAssetResourceLoader, it is possible to load
    // data in a custom way (in our case, to simulate a slow network). Custom URL protocols cannot be used with AVPlayer
}

- (void)testPeriodicTimeObserver
{
    XCTestExpectation *observerExpectation = [self expectationWithDescription:@"Periodic time observer fired"];
    
    __block id periodicTimeObserver = nil;
    
    @weakify(self)
    periodicTimeObserver = [self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        [observerExpectation fulfill];
        
        // Do not fulfill the expectation more than once
        [self.mediaPlayerController removePeriodicTimeObserver:periodicTimeObserver];
    }];
    
    // Periodic time observers fire only when the player has been created
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPeriodicTimeObserverAddedWhilePlaying
{
    XCTestExpectation *observerExpectation = [self expectationWithDescription:@"Periodic time observer fired"];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    __block id periodicTimeObserver = nil;
    
    @weakify(self)
    periodicTimeObserver = [self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        [observerExpectation fulfill];
        
        // Do not fulfill the expectation more than once
        [self.mediaPlayerController removePeriodicTimeObserver:periodicTimeObserver];
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPeriodicTimeObserverWithoutPlayback
{
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    @weakify(self)
    __block id periodicTimeObserver = [self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        XCTFail(@"Periodic time observers are not fired when the player is idle");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [self.mediaPlayerController removePeriodicTimeObserver:periodicTimeObserver];
    }];
}

- (void)testPeriodicTimeObserverAfterReset
{
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    [self.mediaPlayerController reset];
    
    __block id periodicTimeObserver = nil;
    
    @weakify(self)
    periodicTimeObserver = [self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        XCTFail(@"Periodic time observers are not fired when the player is idle");
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [self.mediaPlayerController removePeriodicTimeObserver:periodicTimeObserver];
    }];
}

- (void)testOnDemandStreamEndDefaultTolerance
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:1793.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(CMTIME_COMPARE_INLINE(self.mediaPlayerController.currentTime, ==, CMTimeMakeWithSeconds(1793., NSEC_PER_SEC)));
}

- (void)testOnDemandStreamEndAbsoluteTolerance
{
    self.mediaPlayerController.endTolerance = 10.;
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:1793.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 0., 1.);
}

- (void)testOnDemandStreamEndRelativeTolerance
{
    self.mediaPlayerController.endToleranceRatio = 0.1;         // 10% of the total length
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:1700.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 0., 1.);
}

- (void)testLivestreamEndAbsoluteTolerance
{
    self.mediaPlayerController.endTolerance = 10.;
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 0., 2.);
}

- (void)testDVRStreamEndAbsoluteTolerance
{
    self.mediaPlayerController.endTolerance = 10.;
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:nil withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(CMTIME_COMPARE_INLINE(self.mediaPlayerController.currentTime, >, CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(1., NSEC_PER_SEC))));
}

- (void)testDVRStreamEndSmallestTolerance
{
    self.mediaPlayerController.endTolerance = 10.;
    self.mediaPlayerController.endToleranceRatio = 0.1;         // 10% of the total length 1800 seconds = 180 seconds
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Smallest must win, i.e if we seek ~100 seconds from the end, playback should start at the desired location
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:1700.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(CMTIME_COMPARE_INLINE(self.mediaPlayerController.currentTime, ==, CMTimeMakeWithSeconds(1700., NSEC_PER_SEC)));
}

- (void)testReadyForDisplayForFlatView
{
    XCTAssertFalse(self.mediaPlayerController.view.readyForDisplay);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:1700.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(self.mediaPlayerController.view.readyForDisplay);
    
    [self.mediaPlayerController reset];
    
    XCTAssertFalse(self.mediaPlayerController.view.readyForDisplay);
}

- (void)testReadyForDisplayForMonoscopicView
{
    XCTAssertFalse(self.mediaPlayerController.view.readyForDisplay);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.view.viewMode = SRGMediaPlayerViewModeMonoscopic;
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:[SRGPosition positionAtTimeInSeconds:1700.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(self.mediaPlayerController.view.readyForDisplay);
    
    [self.mediaPlayerController reset];
    
    XCTAssertFalse(self.mediaPlayerController.view.readyForDisplay);
}

@end
