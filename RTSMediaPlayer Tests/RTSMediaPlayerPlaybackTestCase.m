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

- (void) testStopPlayerControllerDoesNotSendNotificationIfNothingHasBeenPlayed
{
	// Count notifications
	__block NSInteger mediaPlayerPlaybackDidFinishNotificationCount = 0;
	[[NSNotificationCenter defaultCenter] addObserverForName:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification *notification) {
		mediaPlayerPlaybackDidFinishNotificationCount++;
	}];
	
	// Force stop with nothing played
	[self.mediaPlayerController stop];
	
	[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
	XCTAssertEqual(mediaPlayerPlaybackDidFinishNotificationCount, 0);
}

- (void) testDestroyPlayerControllerDoesNotSendNotificationIfNothingHasBeenPlayed
{
	// Count notifications
	__block NSInteger mediaPlayerPlaybackDidFinishNotificationCount = 0;
	[[NSNotificationCenter defaultCenter] addObserverForName:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification *notification) {
		mediaPlayerPlaybackDidFinishNotificationCount++;
	}];
	
	// Force stop with nothing played
	self.mediaPlayerController = nil;
	
	[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
	XCTAssertEqual(mediaPlayerPlaybackDidFinishNotificationCount, 0);
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
	
	
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		RTSMediaFinishReason reason = [notification.userInfo[RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
		BOOL reasonUserExited = (reason == RTSMediaFinishReasonUserExited);
		return reasonUserExited;
	}];
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStateIdle;
	}];
	[self.mediaPlayerController stop];
	[self waitForExpectationsWithTimeout:15 handler:nil];
	
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController.player play];
	[self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void) testMultiplePlayDoesNotUpdatePlaybackStateAndDoesNotSendNotifications
{
	__block NSInteger playbackStateKVOChangeCount = 0;
	[self.mediaPlayerController addObservationKeyPath:@"playbackState" options:(NSKeyValueObservingOptions)0 block:^(MAKVONotification *notification) {
		RTSMediaPlayerController *mediaPlayerController = notification.target;
		if (mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying)
			playbackStateKVOChangeCount++;
	}];
	
	__block NSInteger playbackStateNotificationChangeCount = 0;
	[[NSNotificationCenter defaultCenter] addObserverForName:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification *notification) {
		RTSMediaPlayerController *mediaPlayerController = notification.object;
		if (mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying)
			playbackStateNotificationChangeCount++;
	}];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController.player play];
	[self waitForExpectationsWithTimeout:15 handler:nil];
	
	[self.mediaPlayerController.player play];
	[self.mediaPlayerController.player play];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		XCTAssertEqual(playbackStateKVOChangeCount, 1);
		XCTAssertEqual(playbackStateNotificationChangeCount, 1);
		return YES;
	}];
	[self.mediaPlayerController stop];
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

- (void) testPlayingMissingMovieSendsPlaybackDidFinishNotificationWithError
{
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		RTSMediaFinishReason finishReason = [notification.userInfo[RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
		XCTAssertEqual(finishReason, RTSMediaFinishReasonPlaybackError);
		NSError *error = notification.userInfo[RTSMediaPlayerPlaybackDidFinishErrorUserInfoKey];
		XCTAssertEqualObjects(error.domain, AVFoundationErrorDomain);
		XCTAssertEqual(error.code, AVErrorUnknown);
		return YES;
	}];
	[self.mediaPlayerController playIdentifier:@"https://xxx.xxx.xxx/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
	[self waitForExpectationsWithTimeout:15 handler:nil];
}

@end
