//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface MediaPlayerErrorsTestCase : XCTestCase
@end

@implementation MediaPlayerErrorsTestCase

- (void)testHTTP403Error
{
    NSURL *URL = [NSURL URLWithString:@"http://httpbin.org/status/403"];
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackDidFailNotification object:mediaPlayerController handler:^BOOL (NSNotification *notification) {
        NSError *error = notification.userInfo[SRGMediaPlayerErrorKey];
        XCTAssertEqualObjects(error.domain, SRGMediaPlayerErrorDomain);
        XCTAssertEqual(error.code, SRGMediaPlayerErrorPlayback);
        XCTAssertEqual(mediaPlayerController.playbackState, SRGPlaybackStateIdle);
        return YES;
    }];
    
    [mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testHTTP404Error
{
    NSURL *URL = [NSURL URLWithString:@"http://httpbin.org/status/404"];
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackDidFailNotification object:mediaPlayerController handler:^BOOL (NSNotification *notification) {
        NSError *error = notification.userInfo[SRGMediaPlayerErrorKey];
        XCTAssertEqualObjects(error.domain, SRGMediaPlayerErrorDomain);
        XCTAssertEqual(error.code, SRGMediaPlayerErrorPlayback);
        XCTAssertEqual(mediaPlayerController.playbackState, SRGPlaybackStateIdle);
        return YES;
    }];
    
    [mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
