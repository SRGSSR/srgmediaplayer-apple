//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <XCTest/XCTest.h>

static NSURL *MediaPlayerPlaybackTestURL(void)
{
    return [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

@interface MediaPlayerPlaybackTestCase : XCTestCase
@end

@implementation MediaPlayerPlaybackTestCase

- (void)testInitialPlayerStateIsIdle
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
}

- (void)testPrepareAndPlay
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    XCTestExpectation *preparationExpectation = [self expectationWithDescription:@"Prepare and play"];
    
    [mediaPlayerController prepareToPlayURL:MediaPlayerPlaybackTestURL() atTime:kCMTimeZero withCompletionHandler:^{
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
        
        // If we now play, the player just be immediately in the playing state
        [mediaPlayerController play];
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
        
        [preparationExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testMultiplePrepare
{

}

- (void)testMulitplePlay
{

}

- (void)testWithoutPrepare
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    // Playing does not alter the state of the player since it has not been prepared
    [mediaPlayerController play];
    XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
}

- (void)testPrepareToTimeOutsideMedia
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    XCTestExpectation *preparationExpectation = [self expectationWithDescription:@"Prepare"];
    
    [mediaPlayerController prepareToPlayURL:MediaPlayerPlaybackTestURL() atTime:CMTimeMakeWithSeconds(24. * 60. * 60., NSEC_PER_SEC) withCompletionHandler:^{
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
        [preparationExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testMediaInformationAvailabilityAfterPrepare
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    XCTestExpectation *preparationExpectation = [self expectationWithDescription:@"Prepare"];
    
    [mediaPlayerController prepareToPlayURL:MediaPlayerPlaybackTestURL() atTime:kCMTimeZero withCompletionHandler:^{
        XCTAssertEqual(mediaPlayerController.mediaType, SRGMediaPlayerMediaTypeVideo);
        XCTAssertEqual(mediaPlayerController.streamType, SRGMediaPlayerStreamTypeOnDemand);
        [preparationExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testMediaInformationAvailabilityBeforePrepare
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    XCTAssertEqual(mediaPlayerController.mediaType, SRGMediaPlayerMediaTypeUnknown);
    XCTAssertEqual(mediaPlayerController.streamType, SRGMediaPlayerStreamTypeUnknown);
}

- (void)testPlayWithHTTP403Error
{
    NSURL *URL = [NSURL URLWithString:@"http://httpbin.org/status/403"];
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackDidFailNotification object:mediaPlayerController handler:^BOOL (NSNotification *notification) {
        NSError *error = notification.userInfo[SRGMediaPlayerErrorKey];
        XCTAssertEqualObjects(error.domain, SRGMediaPlayerErrorDomain);
        XCTAssertEqual(error.code, SRGMediaPlayerErrorPlayback);
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
        return YES;
    }];
    
    [mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testPrepareWithHTTP404Error
{
    NSURL *URL = [NSURL URLWithString:@"http://httpbin.org/status/404"];
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackDidFailNotification object:mediaPlayerController handler:^BOOL (NSNotification *notification) {
        NSError *error = notification.userInfo[SRGMediaPlayerErrorKey];
        XCTAssertEqualObjects(error.domain, SRGMediaPlayerErrorDomain);
        XCTAssertEqual(error.code, SRGMediaPlayerErrorPlayback);
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
        return YES;
    }];
    
    [mediaPlayerController prepareToPlayURL:URL atTime:kCMTimeZero withCompletionHandler:^{
        XCTFail(@"The completion handler must not be called when the media could not be loaded");
    }];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testSeek
{
    
}

- (void)testMultipleSeeks
{

}

- (void)testSeveralMedias
{

}

- (void)testPlayerLifecycle
{

}

#if 0

- (void)testPlayAndCheckPlayerState
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController play];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePaused;
    }];
    [self.mediaPlayerController pause];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle;
    }];
    [self.mediaPlayerController reset];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController play];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateSeeking;
    }];
    [self.mediaPlayerController playAtTime:CMTimeMakeWithSeconds(5., NSEC_PER_SEC)];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded;
    }];
    [self.mediaPlayerController playAtTime:CMTimeMakeWithSeconds(30. * 60. - 5., NSEC_PER_SEC)];
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayThenResetDoesNotPlayTheMedia
{
    __block NSInteger playbackStateKVOChangeCount = 0;
    [self.mediaPlayerController addObservationKeyPath:@"playbackState" options:(NSKeyValueObservingOptions)0 block:^(MAKVONotification *notification) {
        SRGMediaPlayerController *mediaPlayerController = notification.target;
        if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
            playbackStateKVOChangeCount++;
        }
    }];

    [self.mediaPlayerController play];
    [self.mediaPlayerController reset];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    XCTAssertEqual(playbackStateKVOChangeCount, 0);
}

- (void)testMultiplePlayDoesNotUpdatePlaybackState
{
    __block NSInteger playbackStateKVOChangeCount = 0;
    [self.mediaPlayerController addObservationKeyPath:@"playbackState" options:(NSKeyValueObservingOptions)0 block:^(MAKVONotification *notification) {
        SRGMediaPlayerController *mediaPlayerController = notification.target;
        if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
            playbackStateKVOChangeCount++;
        }
    }];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController play];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self.mediaPlayerController play];
    [self.mediaPlayerController play];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        XCTAssertEqual(playbackStateKVOChangeCount, 1);
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle;
    }];
    [self.mediaPlayerController reset];
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayingMovieWithIdentifier
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayingMissingMovieSendsPlaybackDidFailNotificationWithError
{
    [self expectationForNotification:SRGMediaPlayerPlaybackDidFailNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        XCTAssertNotNil(notification.userInfo[SRGMediaPlayerErrorKey]);
        return YES;
    }];
    [self.mediaPlayerController playIdentifier:@"https://xxx.xxx.xxx/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

#endif

@end
