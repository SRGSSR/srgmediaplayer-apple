//
//  Created by Cédric Luthi on 26.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RTSMediaPlayer/RTSMediaPlayer.h>
#import "NSObject+KVOBlock.h"

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

- (void) testInitialPlayerStateIsPendingPlay
{
	XCTAssertEqual(self.mediaPlayerController.playbackState, RTSMediaPlaybackStatePendingPlay);
}

- (void) testDestroyPlayerControllerSendsNotification
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:nil handler:^BOOL(NSNotification *notification) {
		RTSMediaPlayerController *mediaPlayerController = notification.object;
		BOOL stateEnded = (mediaPlayerController.playbackState == RTSMediaPlaybackStateEnded);
		return stateEnded;
	}];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFinishNotification object:nil handler:^BOOL(NSNotification *notification) {
		RTSMediaFinishReason reason = [notification.userInfo[RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
		BOOL reasonUserExited = (reason == RTSMediaFinishReasonUserExited);
		return reasonUserExited;
	}];
	self.mediaPlayerController = nil;
	[self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void) testPlayAndCheckPlayerState
{
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:5 handler:nil];

	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused;
	}];
	[self.mediaPlayerController pause];
	[self waitForExpectationsWithTimeout:5 handler:nil];
	
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStateEnded;
	}];
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStateEnded;
	}];
	[self.mediaPlayerController stop];
	[self waitForExpectationsWithTimeout:5 handler:nil];
	
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void) testMultiplePlayDoesNotUpdatePlaybackStateAndDoesNotSendNotifications
{
	__block NSInteger playbackStateKVOChangeCount = 0;
	[self.mediaPlayerController observeKeyPath:@"playbackState" withBlock:^(RTSMediaPlayerController *mediaPlayerController, NSString *keyPath, NSDictionary *changes) {
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
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:5 handler:nil];
	
	[self.mediaPlayerController play];
	[self.mediaPlayerController play];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return playbackStateKVOChangeCount == 1 && playbackStateNotificationChangeCount == 1;
	}];
	[self.mediaPlayerController stop];
	[self waitForExpectationsWithTimeout:5 handler:nil];
	
	[self.mediaPlayerController unobserveKeyPath:@"playbackState"];
}

@end
