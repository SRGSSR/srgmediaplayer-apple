//
//  Created by Cédric Luthi on 26.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RTSMediaPlayer/RTSMediaPlayer.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@interface RTSMediaPlayerPlaybackTestCase : XCTestCase
@property RTSMediaPlayerController *mediaPlayerController;
@end

@implementation RTSMediaPlayerPlaybackTestCase

- (void) setUp
{
	NSURL *url = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentURL:url];
}

- (void) tearDown
{
	self.mediaPlayerController = nil;
}

- (void) testInitialPlayerStateIsIdle
{
	XCTAssertEqual(self.mediaPlayerController.playbackState, RTSMediaPlaybackStateIdle);
}

- (void) testPlayAndCheckPlayerState
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController.player play];
	[self waitForExpectationsWithTimeout:15 handler:nil];

	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused;
	}];
	[self.mediaPlayerController.player pause];
	[self waitForExpectationsWithTimeout:15 handler:nil];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStateIdle;
	}];
	[self.mediaPlayerController reset];
	[self waitForExpectationsWithTimeout:15 handler:nil];
	
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController.player play];
	[self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void) testMultiplePlayDoesNotUpdatePlaybackState
{
	__block NSInteger playbackStateKVOChangeCount = 0;
	[self.mediaPlayerController addObservationKeyPath:@"playbackState" options:(NSKeyValueObservingOptions)0 block:^(MAKVONotification *notification) {
		RTSMediaPlayerController *mediaPlayerController = notification.target;
		if (mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying)
			playbackStateKVOChangeCount++;
	}];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController.player play];
	[self waitForExpectationsWithTimeout:15 handler:nil];
	
	[self.mediaPlayerController.player play];
	[self.mediaPlayerController.player play];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		XCTAssertEqual(playbackStateKVOChangeCount, 1);
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStateIdle;
	}];
	[self.mediaPlayerController reset];
	[self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void) testPlayingMovieWithIdentifier
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController playIdentifier:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
	[self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void) testPlayingMissingMovieSendsPlaybackDidFailNotificationWithError
{
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFailNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		NSError *error = notification.userInfo[RTSMediaPlayerPlaybackDidFailErrorUserInfoKey];
		XCTAssertEqualObjects(error.domain, AVFoundationErrorDomain);
		XCTAssertEqual(error.code, AVErrorUnknown);
		return YES;
	}];
	[self.mediaPlayerController playIdentifier:@"https://xxx.xxx.xxx/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
	[self waitForExpectationsWithTimeout:15 handler:nil];
}

@end
