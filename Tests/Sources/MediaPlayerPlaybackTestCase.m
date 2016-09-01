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

- (void)testPrepare
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    // After completion handler execution, the player state is updated. Since nothing is done in the completion handler,
    // the player must be paused
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        // Ignore the notification associated with the preparing phase
        if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
            return NO;
        }
        
        // Check the next notification
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
        return YES;
    }];
    
    [mediaPlayerController prepareToPlayURL:MediaPlayerPlaybackTestURL() atTime:kCMTimeZero withCompletionHandler:^{
        // Upon completion handler entry, the state is always preparing
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPrepareAndPlay
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    XCTestExpectation *preparationExpectation = [self expectationWithDescription:@"Playing"];
    
    [mediaPlayerController prepareToPlayURL:MediaPlayerPlaybackTestURL() atTime:kCMTimeZero withCompletionHandler:^{
        // Upon completion handler entry, the state is always preparing
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
        
        // If we now play, the player just be immediately in the playing state
        [mediaPlayerController play];
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
        
        [preparationExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testMultiplePrepare
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    [mediaPlayerController prepareToPlayURL:MediaPlayerPlaybackTestURL() atTime:kCMTimeZero withCompletionHandler:^{
        XCTFail(@"The completion handler must not be called since a second prepare must cancel the first");
    }];
    
    XCTestExpectation *preparationExpectation = [self expectationWithDescription:@"Prepared"];
    
    [mediaPlayerController prepareToPlayURL:MediaPlayerPlaybackTestURL() atTime:kCMTimeZero withCompletionHandler:^{
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
        [preparationExpectation fulfill];
    }];
    
   [self waitForExpectationsWithTimeout:30. handler:nil];
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
    
    // After completion handler execution, the player state is updated. Since nothing is done in the completion handler,
    // the player must be paused
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        // Ignore the notification associated with the preparing phase
        if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
            return NO;
        }
        
        // Check the next notification
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
        return YES;
    }];
    
    [mediaPlayerController prepareToPlayURL:MediaPlayerPlaybackTestURL() atTime:CMTimeMakeWithSeconds(24. * 60. * 60., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlay
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        // Ignore the notification associated with the preparing phase
        if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
            return NO;
        }
        
        // The player must have transitioned directly to the playing state without going through the paused state
        XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
        return YES;
    }];
    
    [mediaPlayerController playURL:MediaPlayerPlaybackTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testMediaInformationAvailabilityAfterPrepare
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    XCTestExpectation *preparationExpectation = [self expectationWithDescription:@"Prepared"];
    
    [mediaPlayerController prepareToPlayURL:MediaPlayerPlaybackTestURL() atTime:kCMTimeZero withCompletionHandler:^{
        XCTAssertEqual(mediaPlayerController.mediaType, SRGMediaPlayerMediaTypeVideo);
        XCTAssertEqual(mediaPlayerController.streamType, SRGMediaPlayerStreamTypeOnDemand);
        [preparationExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
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
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
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
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekWhilePaused
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the paused state to seek
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if (mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePaused) {
            return NO;
        }
        
        [mediaPlayerController seekToTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withCompletionHandler:^(BOOL finished) {
            // No seek could have interrupted this one
            XCTAssertTrue(finished);
            
            // The player must still be paused after the seek
            XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
            
            [seekFinishedExpectation fulfill];
        }];
        
        return YES;
    }];
    
    [mediaPlayerController prepareToPlayURL:MediaPlayerPlaybackTestURL() withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekWhilePlaying
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the playing state to seek
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if (mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePlaying) {
            return NO;
        }
        
        [mediaPlayerController seekToTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withCompletionHandler:^(BOOL finished) {
            // No seek could have interrupted this one
            XCTAssertTrue(finished);
            
            // The player must still be playing after the seek
            XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
            
            [seekFinishedExpectation fulfill];
        }];
        
        return YES;
    }];
    
    [mediaPlayerController playURL:MediaPlayerPlaybackTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSeekWithoutPrepare
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    [mediaPlayerController seekToTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withCompletionHandler:^(BOOL finished) {
        XCTFail(@"The completion handler must not be called since a seek must do nothing if the media was not prepared");
    }];
    XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateIdle);
}

- (void)testSeekInterruption
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    XCTestExpectation *seekFinishedExpectation = [self expectationWithDescription:@"Seek finished"];
    
    // Wait until the player is in the playing state to seek
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        if (mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePlaying) {
            return NO;
        }
        
        [mediaPlayerController seekToTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withCompletionHandler:^(BOOL finished) {
            // This seek must have been interrupted by the second one
            XCTAssertFalse(finished);
            XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStateSeeking);
        }];
        [mediaPlayerController seekToTime:CMTimeMakeWithSeconds(50., NSEC_PER_SEC) withCompletionHandler:^(BOOL finished) {
            XCTAssertTrue(finished);
            XCTAssertEqual(mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
            
            [seekFinishedExpectation fulfill];
        }];
        
        return YES;
    }];
    
    [mediaPlayerController playURL:MediaPlayerPlaybackTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testReset
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    // Wait until playing
    {
        [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            return mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
        }];
        
        // Pass an empty array for segments
        [mediaPlayerController playURL:MediaPlayerPlaybackTestURL() withSegments:@[]];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
    }
    
    // Reset the player and check its status
    {
        [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            if (mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle) {
                return NO;
            }
            
            XCTAssertNil(mediaPlayerController.contentURL);
            XCTAssertNil(mediaPlayerController.segments);
            
            return YES;
        }];
        
        XCTAssertNotNil(mediaPlayerController.contentURL);
        XCTAssertNotNil(mediaPlayerController.segments);
        
        [mediaPlayerController reset];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
    }
}

- (void)testConsecutiveMediaPlaybackInSamePlayer
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    // Wait until playing
    {
        [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            return mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
        }];
        
        [mediaPlayerController playURL:MediaPlayerPlaybackTestURL() withSegments:nil];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
    }
    
    // Wait until playing again. Expect a playback state change to idle, then to play
    {
        [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            return (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle);
        }];
        [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            return (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying);
        }];
        
        [mediaPlayerController playURL:MediaPlayerPlaybackTestURL() withSegments:nil];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
    }
}

- (void)testPlayerLifecycle
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    // Wait until playing
    {
        [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            return mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
        }];
        
        XCTestExpectation *creationExpectation = [self expectationWithDescription:@"Player created"];
        mediaPlayerController.playerCreationBlock = ^(AVPlayer *player) {
            [creationExpectation fulfill];
        };
        
        XCTestExpectation *configurationReloadExpectation = [self expectationWithDescription:@"Configuration reloaded"];
        mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
            [configurationReloadExpectation fulfill];
        };
        
        [mediaPlayerController playURL:MediaPlayerPlaybackTestURL() withSegments:nil];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
    }
    
    // Reset the player
    {
        [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            return mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle;
        }];
        
        XCTestExpectation *destructionExpectation = [self expectationWithDescription:@"Player destroyed"];
        mediaPlayerController.playerDestructionBlock = ^(AVPlayer *player) {
            [destructionExpectation fulfill];
        };
        
        [mediaPlayerController reset];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
    }
}

- (void)testConfigurationReload
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    // Wait until playing
    {
        [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
            return mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
        }];
        
        XCTestExpectation *creationExpectation = [self expectationWithDescription:@"Player created"];
        mediaPlayerController.playerCreationBlock = ^(AVPlayer *player) {
            [creationExpectation fulfill];
        };
        
        XCTestExpectation *configurationReloadExpectation = [self expectationWithDescription:@"Configuration reloaded"];
        mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
            [configurationReloadExpectation fulfill];
        };
        
        [mediaPlayerController playURL:MediaPlayerPlaybackTestURL() withSegments:nil];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
    }
    
    // Reload the configuration
    {
        XCTestExpectation *configurationReloadExpectation = [self expectationWithDescription:@"Configuration reloaded"];
        mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
            [configurationReloadExpectation fulfill];
        };
        
        [mediaPlayerController reloadPlayerConfiguration];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
    }
}

- (void)testConfigurationReloadBeforePlayerIsAvailable
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
        XCTFail(@"Player configuration must not be called if no player is available");
    };
    
    [mediaPlayerController reloadPlayerConfiguration];
}

- (void)testPlaybackStateKeyValueObserving
{

}

- (void)testStalled
{
    // Idea (might take some time to implement, later): Implement custom URL protocol forwarding to the system protocol, but adding
    // some sleeps before returning the data
}

#if 0

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

#endif

@end
