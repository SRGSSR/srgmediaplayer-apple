//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <XCTest/XCTest.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>
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
	XCTAssertEqual(self.mediaPlayerController.playbackState, RTSPlaybackStateIdle);
}

- (void) testPlayAndCheckPlayerState
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSPlaybackStatePlaying;
	}];
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:30. handler:nil];

	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSPlaybackStatePaused;
	}];
	[self.mediaPlayerController pause];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSPlaybackStateIdle;
	}];
	[self.mediaPlayerController reset];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSPlaybackStatePlaying;
	}];
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSPlaybackStateSeeking;
	}];
	[self.mediaPlayerController playAtTime:CMTimeMakeWithSeconds(5., 1.)];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSPlaybackStateEnded;
	}];
	[self.mediaPlayerController playAtTime:CMTimeMakeWithSeconds(30. * 60. - 5., 1.)];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void) testPlayThenResetDoesNotPlayTheMedia
{
	__block NSInteger playbackStateKVOChangeCount = 0;
	[self.mediaPlayerController addObservationKeyPath:@"playbackState" options:(NSKeyValueObservingOptions)0 block:^(MAKVONotification *notification) {
		RTSMediaPlayerController *mediaPlayerController = notification.target;
		if (mediaPlayerController.playbackState == RTSPlaybackStatePlaying)
			playbackStateKVOChangeCount++;
	}];
	
	[self.mediaPlayerController play];
	[self.mediaPlayerController reset];
	[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	XCTAssertEqual(playbackStateKVOChangeCount, 0);
}

- (void) testMultiplePlayDoesNotUpdatePlaybackState
{
	__block NSInteger playbackStateKVOChangeCount = 0;
	[self.mediaPlayerController addObservationKeyPath:@"playbackState" options:(NSKeyValueObservingOptions)0 block:^(MAKVONotification *notification) {
		RTSMediaPlayerController *mediaPlayerController = notification.target;
		if (mediaPlayerController.playbackState == RTSPlaybackStatePlaying)
			playbackStateKVOChangeCount++;
	}];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSPlaybackStatePlaying;
	}];
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:30. handler:nil];
	
	[self.mediaPlayerController play];
	[self.mediaPlayerController play];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		XCTAssertEqual(playbackStateKVOChangeCount, 1);
		return self.mediaPlayerController.playbackState == RTSPlaybackStateIdle;
	}];
	[self.mediaPlayerController reset];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void) testPlayingMovieWithIdentifier
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSPlaybackStatePlaying;
	}];
	[self.mediaPlayerController playIdentifier:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void) testPlayingMissingMovieSendsPlaybackDidFailNotificationWithError
{
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFailNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		XCTAssertNotNil(notification.userInfo[RTSMediaPlayerPlaybackDidFailErrorUserInfoKey]);
		return YES;
	}];
	[self.mediaPlayerController playIdentifier:@"https://xxx.xxx.xxx/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
	[self waitForExpectationsWithTimeout:30. handler:nil];
}

@end
