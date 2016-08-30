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

- (id)mediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSString *identifier, NSURL *, NSError *))completionHandler
{
    completionHandler(identifier, nil, [NSError errorWithDomain:@"AppDomain" code:-1 userInfo:nil]);

    // No need for a connection identifier, completion handlers are called immediately
    return nil;
}

- (void)cancelContentURLRequest:(id)request
{}

@end

@interface InvalidDataSource : NSObject <RTSMediaPlayerControllerDataSource> @end

@implementation InvalidDataSource

- (id)mediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSString *identifier, NSURL *, NSError *))completionHandler
{
    completionHandler(identifier, nil, nil);

    // No need for a connection identifier, completion handlers are called immediately
    return nil;
}

- (void)cancelContentURLRequest:(id)request
{}

@end

@interface SRGMediaPlayerErrorsTestCase : XCTestCase
@end

@implementation SRGMediaPlayerErrorsTestCase

- (void)testDataSourceError
{
    id<RTSMediaPlayerControllerDataSource> dataSource = [DataSourceReturningError new];
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] initWithContentIdentifier:@"" dataSource:dataSource];
    [self expectationForNotification:SRGMediaPlayerPlaybackDidFailNotification object:mediaPlayerController handler:^BOOL (NSNotification *notification) {
        NSError *error = notification.userInfo[SRGMediaPlayerErrorKey];
        XCTAssertEqualObjects(error.domain, @"AppDomain");
        XCTAssertEqual(error.code, -1);
        return YES;
    }];
    [mediaPlayerController play];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testInvalidDataSourceImplementation
{
    id<RTSMediaPlayerControllerDataSource> dataSource = [InvalidDataSource new];
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] initWithContentIdentifier:@"" dataSource:dataSource];
    [self expectationForNotification:SRGMediaPlayerPlaybackDidFailNotification object:mediaPlayerController handler:^BOOL (NSNotification *notification) {
        NSError *error = notification.userInfo[SRGMediaPlayerErrorKey];
        XCTAssertEqualObjects(error.domain, SRGMediaPlayerErrorDomain);
        XCTAssertEqual(error.code, SRGMediaPlayerErrorDataSource);
        return YES;
    }];
    [mediaPlayerController play];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testHTTP403Error
{
    NSURL *url = [NSURL URLWithString:@"http://httpbin.org/status/403"];
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] initWithContentURL:url];
    [self expectationForNotification:SRGMediaPlayerPlaybackDidFailNotification object:mediaPlayerController handler:^BOOL (NSNotification *notification) {
        NSError *error = notification.userInfo[SRGMediaPlayerErrorKey];
        XCTAssertEqualObjects(error.domain, SRGMediaPlayerErrorDomain);
        XCTAssertEqual(error.code, SRGMediaPlayerErrorPlayback);
        return YES;
    }];
    [mediaPlayerController play];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
