//
//  RTSMediaPlayerLoadStateTestCase.m
//  RTSMediaPlayer
//
//  Created by Frédéric Humbert-Droz on 02/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RTSMediaPlayer/RTSMediaPlayer.h>
#import "RTSMediaPlayerTestDataSource.h"

#import <TransitionKit/TransitionKit.h>

@interface RTSMediaPlayerLoadStateTestCase : XCTestCase
@property (nonatomic, strong) TKStateMachine *loadStateMachine;
@property (nonatomic, strong) RTSMediaPlayerController *mediaPlayerController;
@end

@implementation RTSMediaPlayerLoadStateTestCase

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	_mediaPlayerController = mediaPlayerController;
	_loadStateMachine = [_mediaPlayerController valueForKeyPath:@"loadStateMachine"];
}

- (void) expectationForStateMachineFromState:(NSString *)oldStateName toState:(NSString *)newStateName completionHandler:(void (^)(void))completionHandler
{
	[self keyValueObservingExpectationForObject:self.loadStateMachine keyPath:@"currentState" handler:^BOOL(TKStateMachine *stateMachine, NSDictionary *change)
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

- (void) testInitialLoadStateMachine
{
	RTSMediaPlayerTestDataSource *dataSource = [[RTSMediaPlayerTestDataSource alloc] initWithContentType:RTSDataSourceTestContentTypeAppleStreamingBasicSample];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:@"id1" dataSource:dataSource];

	XCTAssertEqualObjects(self.loadStateMachine.currentState.name, @"None");
}

- (void) testStateMachineEvents
{
	RTSMediaPlayerTestDataSource *dataSource = [[RTSMediaPlayerTestDataSource alloc] initWithContentType:RTSDataSourceTestContentTypeAppleStreamingBasicSample];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:@"id1" dataSource:dataSource];

	[self expectationForStateMachineFromState:@"None" toState:@"Loading Content URL" completionHandler:^{
		[self expectationForStateMachineFromState:@"Loading Content URL" toState:@"Content URL Loaded" completionHandler:^{
			[self expectationForStateMachineFromState:@"Content URL Loaded" toState:@"Loading Asset" completionHandler:^{
				[self expectationForStateMachineFromState:@"Loading Asset" toState:@"Asset Loaded" completionHandler:^{
					XCTAssertNotNil(self.mediaPlayerController.player);
				}];
			}];
		}];
	}];
	
	[self.loadStateMachine fireEvent:@"Load Content URL" userInfo:nil error:nil];
	[self waitForExpectationsWithTimeout:5 handler:nil];
}



#pragma mark - Content URL

- (void) testDataSourceThatReturnsContentURLError
{
	RTSMediaPlayerTestDataSource *dataSource = [[RTSMediaPlayerTestDataSource alloc] initWithContentType:RTSDataSourceTestContentTypeContentURLError];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:@"id1" dataSource:dataSource];

	[self expectationForStateMachineFromState:@"None" toState:@"Loading Content URL" completionHandler:^{
		[self expectationForStateMachineFromState:@"Loading Content URL" toState:@"None" completionHandler:nil];
	}];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFinishNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		RTSMediaFinishReason reason = [notification.userInfo[RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
		return (reason == RTSMediaFinishReasonPlaybackError);
	}];
	
	[self.loadStateMachine fireEvent:@"Load Content URL" userInfo:nil error:nil];
	[self waitForExpectationsWithTimeout:5 handler:nil];
}



#pragma mark - Asset

- (void) testAssetDoesNotExistsReturns404
{
	RTSMediaPlayerTestDataSource *dataSource = [[RTSMediaPlayerTestDataSource alloc] initWithContentType:RTSDataSourceTestContentTypeAsset404Error];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:@"id1" dataSource:dataSource];

	[self expectationForStateMachineFromState:@"None" toState:@"Loading Content URL" completionHandler:^{
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
	
	[self.loadStateMachine fireEvent:@"Load Content URL" userInfo:nil error:nil];
	[self waitForExpectationsWithTimeout:5 handler:nil];
	
}

- (void) testAssetIsNotAccessibleReturns403
{
	RTSMediaPlayerTestDataSource *dataSource = [[RTSMediaPlayerTestDataSource alloc] initWithContentType:RTSDataSourceTestContentTypeAsset403Error];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:@"id1" dataSource:dataSource];
	
	[self expectationForStateMachineFromState:@"None" toState:@"Loading Content URL" completionHandler:^{
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
	
	[self.loadStateMachine fireEvent:@"Load Content URL" userInfo:nil error:nil];
	[self waitForExpectationsWithTimeout:5 handler:nil];
}



#pragma mark - Reseting

- (void) testPlayerPauseAndStateMachineKeepItsState
{
	RTSMediaPlayerTestDataSource *dataSource = [[RTSMediaPlayerTestDataSource alloc] initWithContentType:RTSDataSourceTestContentTypeAppleStreamingBasicSample];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:@"id1" dataSource:dataSource];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:5 handler:nil];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePaused && [self.loadStateMachine.currentState.name isEqualToString:@"Asset Loaded"];
	}];
	[self.mediaPlayerController pause];
	[self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void) testPlayerStopAndStateMachineIsReset
{
	RTSMediaPlayerTestDataSource *dataSource = [[RTSMediaPlayerTestDataSource alloc] initWithContentType:RTSDataSourceTestContentTypeAppleStreamingBasicSample];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:@"id1" dataSource:dataSource];
	
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:5 handler:nil];
	
	[self expectationForStateMachineFromState:@"Asset Loaded" toState:@"None" completionHandler:^{
		XCTAssertNil(self.mediaPlayerController.player);
	}];
	[self.mediaPlayerController stop];
	[self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void) testPlayIdentifierResetStateMachineAndLoadNewAsset
{
	NSString *appleStreamingBasicSampleIdentifier = [RTSMediaPlayerTestDataSource contentURLForContentType:RTSDataSourceTestContentTypeAppleStreamingBasicSample].absoluteString;
	
	RTSMediaPlayerTestDataSource *dataSource = [[RTSMediaPlayerTestDataSource alloc] initWithContentType:RTSDataSourceTestContentTypeIdentifier];
	self.mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:appleStreamingBasicSampleIdentifier dataSource:dataSource];

	// Start playing
	[self expectationForNotification:RTSMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification *notification) {
		return self.mediaPlayerController.playbackState == RTSMediaPlaybackStatePlaying;
	}];
	[self.mediaPlayerController play];
	[self waitForExpectationsWithTimeout:5 handler:nil];
	
	// Play another stream
	NSString *appleStreamingAdvancedSampleIdentifier = [RTSMediaPlayerTestDataSource contentURLForContentType:RTSDataSourceTestContentTypeAppleStreamingAdvancedSample].absoluteString;
	[self expectationForStateMachineFromState:@"Asset Loaded" toState:@"None" completionHandler:^{
		[self expectationForStateMachineFromState:@"None" toState:@"Loading Content URL" completionHandler:^{
			[self expectationForStateMachineFromState:@"Loading Content URL" toState:@"Content URL Loaded" completionHandler:^{
				[self expectationForStateMachineFromState:@"Content URL Loaded" toState:@"Loading Asset" completionHandler:^{
					[self expectationForStateMachineFromState:@"Loading Asset" toState:@"Asset Loaded" completionHandler:nil];
				}];
			}];
		}];
	}];
	[self.mediaPlayerController playIdentifier:appleStreamingAdvancedSampleIdentifier];
	[self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
