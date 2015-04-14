//
//  RTSMediaPlayerLoadStateTestCase.m
//  RTSMediaPlayer
//
//  Created by Frédéric Humbert-Droz on 02/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RTSMediaPlayer/RTSMediaPlayer.h>

#import <TransitionKit/TransitionKit.h>


@interface DataSourceReturningError : NSObject <RTSMediaPlayerControllerDataSource>
@end

@implementation DataSourceReturningError
- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	completionHandler(nil, [NSError errorWithDomain:@"Domain" code:-1 userInfo:nil]);
}
@end


@interface RTSMediaPlayerLoadStateTestCase : XCTestCase
@property (nonatomic, strong) TKStateMachine *stateMachine;
@property (nonatomic, strong) RTSMediaPlayerController *mediaPlayerController;
@end

@implementation RTSMediaPlayerLoadStateTestCase

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	_mediaPlayerController = mediaPlayerController;
	self.stateMachine = [_mediaPlayerController valueForKeyPath:@"stateMachine"];
}

- (XCTestExpectation *) expectationForStateMachineFromState:(NSString *)oldStateName toState:(NSString *)newStateName completionHandler:(void (^)(void))completionHandler
{
	return [self keyValueObservingExpectationForObject:self.stateMachine keyPath:@"currentState" handler:^BOOL(TKStateMachine *stateMachine, NSDictionary *change)
	{
		TKState *oldState = change[NSKeyValueChangeOldKey];
		TKState *newState = change[NSKeyValueChangeNewKey];
		BOOL success = [oldState.name isEqualToString:oldStateName] && [newState.name isEqualToString:newStateName];
		
		NSLog(@"%@ -> %@ (%@)", oldState.name, newState.name, success ? @"Success" : @"Fail");
		if (success && completionHandler)
			completionHandler();
		
		return success;
	}];
}



#pragma mark - Setup

- (void) tearDown
{
	[super tearDown];
	self.mediaPlayerController = nil;
}



#pragma mark - State Machine

- (void) testInitialstateMachine
{
	self.mediaPlayerController = [RTSMediaPlayerController new];
	XCTAssertEqualObjects(self.stateMachine.currentState.name, @"Idle");
}

- (void) testStateMachineEvents
{
	NSURL *basicHLSStreamURL = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentURL:basicHLSStreamURL];

	[self expectationForStateMachineFromState:@"Idle" toState:@"Loading Content URL" completionHandler:^{
		[self expectationForStateMachineFromState:@"Loading Content URL" toState:@"Content URL Loaded" completionHandler:^{
			[self expectationForStateMachineFromState:@"Content URL Loaded" toState:@"Loading Asset" completionHandler:^{
				[self expectationForStateMachineFromState:@"Loading Asset" toState:@"Asset Loaded" completionHandler:^{
					XCTAssertNotNil(self.mediaPlayerController.player);
				}];
			}];
		}];
	}];
	
	[self.stateMachine fireEvent:@"Load Content URL" userInfo:nil error:nil];
	[self waitForExpectationsWithTimeout:15 handler:nil];
}



#pragma mark - Content URL

- (void) testDataSourceThatReturnsContentURLError
{
	DataSourceReturningError *dataSource = [DataSourceReturningError new];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:@"id1" dataSource:dataSource];

	[self expectationForStateMachineFromState:@"Idle" toState:@"Loading Content URL" completionHandler:^{
		[self expectationForStateMachineFromState:@"Loading Content URL" toState:@"Idle" completionHandler:nil];
	}];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		RTSMediaFinishReason reason = [notification.userInfo[RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
		return (reason == RTSMediaFinishReasonPlaybackError);
	}];
	
	[self.stateMachine fireEvent:@"Load Content URL" userInfo:nil error:nil];
	[self waitForExpectationsWithTimeout:1 handler:nil];
}



#pragma mark - Asset

- (void) testAssetDoesNotExistsReturns404
{
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentURL:[NSURL URLWithString:@"http://httpbin.org/status/404"]];

	[self expectationForStateMachineFromState:@"Idle" toState:@"Loading Content URL" completionHandler:^{
		[self expectationForStateMachineFromState:@"Loading Content URL" toState:@"Content URL Loaded" completionHandler:^{
			[self expectationForStateMachineFromState:@"Content URL Loaded" toState:@"Loading Asset" completionHandler:^{
				[self expectationForStateMachineFromState:@"Loading Asset" toState:@"Content URL Loaded" completionHandler:nil];
			}];
		}];
	}];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		RTSMediaFinishReason reason = [notification.userInfo[RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
		NSError *error = notification.userInfo[RTSMediaPlayerPlaybackDidFinishErrorUserInfoKey];
		return (reason == RTSMediaFinishReasonPlaybackError) && error.code == NSURLErrorFileDoesNotExist;
	}];
	
	[self.stateMachine fireEvent:@"Load Content URL" userInfo:nil error:nil];
	[self waitForExpectationsWithTimeout:15 handler:nil];
	
}

- (void) testAssetIsNotAccessibleReturns403
{
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentURL:[NSURL URLWithString:@"http://httpbin.org/status/403"]];
	
	[self expectationForStateMachineFromState:@"Idle" toState:@"Loading Content URL" completionHandler:^{
		[self expectationForStateMachineFromState:@"Loading Content URL" toState:@"Content URL Loaded" completionHandler:^{
			[self expectationForStateMachineFromState:@"Content URL Loaded" toState:@"Loading Asset" completionHandler:^{
				[self expectationForStateMachineFromState:@"Loading Asset" toState:@"Content URL Loaded" completionHandler:nil];
			}];
		}];
	}];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		RTSMediaFinishReason reason = [notification.userInfo[RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
		NSError *error = notification.userInfo[RTSMediaPlayerPlaybackDidFinishErrorUserInfoKey];
		return (reason == RTSMediaFinishReasonPlaybackError) && error.code == -11800;
	}];
	
	[self.stateMachine fireEvent:@"Load Content URL" userInfo:nil error:nil];
	[self waitForExpectationsWithTimeout:15 handler:nil];
}



#pragma mark - Reseting

- (void) testPlayerPauseAndStateMachineKeepItsState
{
	NSURL *basicHLSStreamURL = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentURL:basicHLSStreamURL];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:15 handler:nil];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused && [self.stateMachine.currentState.name isEqualToString:@"Asset Loaded"];
	}];
	[self.mediaPlayerController.player pause];
	[self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void) testPlayerStopAndStateMachineIsReset
{
	NSURL *basicHLSStreamURL = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentURL:basicHLSStreamURL];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:15 handler:nil];
	
	[self expectationForStateMachineFromState:@"Asset Loaded" toState:@"Idle" completionHandler:^{
		XCTAssertNil(self.mediaPlayerController.player);
	}];
	[self.mediaPlayerController reset];
	[self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void) testPlayIdentifierResetStateMachineAndLoadNewAsset
{
	NSURL *basicHLSStreamURL = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentURL:basicHLSStreamURL];

	// Start playing
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:15 handler:nil];
	
	// Play another stream
	[self expectationForStateMachineFromState:@"Asset Loaded" toState:@"Idle" completionHandler:^{
		[self expectationForStateMachineFromState:@"Idle" toState:@"Loading Content URL" completionHandler:^{
			[self expectationForStateMachineFromState:@"Loading Content URL" toState:@"Content URL Loaded" completionHandler:^{
				[self expectationForStateMachineFromState:@"Content URL Loaded" toState:@"Loading Asset" completionHandler:^{
					[self expectationForStateMachineFromState:@"Loading Asset" toState:@"Asset Loaded" completionHandler:nil];
				}];
			}];
		}];
	}];
	NSString *advancedHLSStream = @"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8";
	[self.mediaPlayerController playIdentifier:advancedHLSStream];
	[self waitForExpectationsWithTimeout:15 handler:nil];
}

@end
