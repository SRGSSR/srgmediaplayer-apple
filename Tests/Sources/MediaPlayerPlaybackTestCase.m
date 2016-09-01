//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <XCTest/XCTest.h>

static NSString * const MediaPlayerPlaybackTestURL = @"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8";

@interface MediaPlayerPlaybackTestCase : XCTestCase
@end

@implementation MediaPlayerPlaybackTestCase

- (void)testInitialPlayerStateIsIdle
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    XCTAssertEqual(mediaPlayerController.playbackState, SRGPlaybackStateIdle);
}

#if 0

- (void)testPlayAndCheckPlayerState
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGPlaybackStatePlaying;
    }];
    [self.mediaPlayerController play];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGPlaybackStatePaused;
    }];
    [self.mediaPlayerController pause];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGPlaybackStateIdle;
    }];
    [self.mediaPlayerController reset];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGPlaybackStatePlaying;
    }];
    [self.mediaPlayerController play];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGPlaybackStateSeeking;
    }];
    [self.mediaPlayerController playAtTime:CMTimeMakeWithSeconds(5., NSEC_PER_SEC)];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGPlaybackStateEnded;
    }];
    [self.mediaPlayerController playAtTime:CMTimeMakeWithSeconds(30. * 60. - 5., NSEC_PER_SEC)];
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayThenResetDoesNotPlayTheMedia
{
    __block NSInteger playbackStateKVOChangeCount = 0;
    [self.mediaPlayerController addObservationKeyPath:@"playbackState" options:(NSKeyValueObservingOptions)0 block:^(MAKVONotification *notification) {
        SRGMediaPlayerController *mediaPlayerController = notification.target;
        if (mediaPlayerController.playbackState == SRGPlaybackStatePlaying) {
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
        if (mediaPlayerController.playbackState == SRGPlaybackStatePlaying) {
            playbackStateKVOChangeCount++;
        }
    }];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGPlaybackStatePlaying;
    }];
    [self.mediaPlayerController play];
    [self waitForExpectationsWithTimeout:30. handler:nil];

    [self.mediaPlayerController play];
    [self.mediaPlayerController play];

    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        XCTAssertEqual(playbackStateKVOChangeCount, 1);
        return self.mediaPlayerController.playbackState == SRGPlaybackStateIdle;
    }];
    [self.mediaPlayerController reset];
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlayingMovieWithIdentifier
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGPlaybackStatePlaying;
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
