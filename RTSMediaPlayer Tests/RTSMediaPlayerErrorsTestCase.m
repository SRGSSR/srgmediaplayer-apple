//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <SRGMediaPlayer/SRGMediaPlayer.h>


@interface DataSourceReturningError : NSObject <RTSMediaPlayerControllerDataSource> @end
@implementation DataSourceReturningError
- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	completionHandler(nil, [NSError errorWithDomain:@"AppDomain" code:-1 userInfo:nil]);
}
@end

@interface InvalidDataSource : NSObject <RTSMediaPlayerControllerDataSource> @end
@implementation InvalidDataSource
- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	completionHandler(nil, nil);
}
@end


@interface RTSMediaPlayerErrorsTestCase : XCTestCase
@end

@implementation RTSMediaPlayerErrorsTestCase

- (void) testDataSourceError
{
	id<RTSMediaPlayerControllerDataSource> dataSource = [DataSourceReturningError new];
	RTSMediaPlayerController *mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:@"" dataSource:dataSource];
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFailNotification object:mediaPlayerController handler:^BOOL(NSNotification *notification) {
		NSError *error = notification.userInfo[RTSMediaPlayerPlaybackDidFailErrorUserInfoKey];
		XCTAssertEqualObjects(error.domain, @"AppDomain");
		XCTAssertEqual(error.code, -1);
		return YES;
	}];
	[mediaPlayerController play];
	[self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void) testInvalidDataSourceImplementation
{
	id<RTSMediaPlayerControllerDataSource> dataSource = [InvalidDataSource new];
	RTSMediaPlayerController *mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentIdentifier:@"" dataSource:dataSource];
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFailNotification object:mediaPlayerController handler:^BOOL(NSNotification *notification) {
		NSError *error = notification.userInfo[RTSMediaPlayerPlaybackDidFailErrorUserInfoKey];
		XCTAssertEqualObjects(error.domain, RTSMediaPlayerErrorDomain);
		XCTAssertEqual(error.code, RTSMediaPlayerErrorUnknown);
		XCTAssertEqualObjects(error.localizedDescription, @"An unknown error occured.");
		XCTAssertEqualObjects(error.localizedFailureReason, @"The RTSMediaPlayerControllerDataSource implementation returned a nil contentURL and a nil error.");
		return YES;
	}];
	[mediaPlayerController play];
	[self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void) testHTTP403Error
{
	NSURL *url = [NSURL URLWithString:@"http://httpbin.org/status/403"];
	RTSMediaPlayerController *mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentURL:url];
	[self expectationForNotification:RTSMediaPlayerPlaybackDidFailNotification object:mediaPlayerController handler:^BOOL(NSNotification *notification) {
		NSError *error = notification.userInfo[RTSMediaPlayerPlaybackDidFailErrorUserInfoKey];
		XCTAssertEqualObjects(error.domain, AVFoundationErrorDomain);
		XCTAssertEqual(error.code, AVErrorUnknown);
		return YES;
	}];
	[mediaPlayerController play];
	[self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
