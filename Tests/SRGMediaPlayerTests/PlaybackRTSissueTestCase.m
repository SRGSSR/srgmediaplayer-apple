//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"
#import "TestMacros.h"

@import libextobjc;
@import MAKVONotificationCenter;
@import SRGMediaPlayer;

static NSURL *AppleBipBopOnDemandTestURL(void)
{
    return [NSURL URLWithString:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

static NSURL *RTSWWOnDemandTestURL(void)
{
    return [NSURL URLWithString:@"https://rts-vod-amd.akamaized.net/ww/hls/12063264/27f6b361-ba1c-3b8d-91d3-3330e17c4cc3/master.m3u8"];
}

static NSURL *RTSCHOnDemandTestURL(void)
{
    return [NSURL URLWithString:@"https://rts-vod-amd.akamaized.net/ch/hls/11986730/95e3d258-9200-38b1-b3ea-19cbc42ee0c9/master.m3u8"];
}


@interface PlaybackRTSissueTestCase : MediaPlayerBaseTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation PlaybackRTSissueTestCase

#pragma mark Setup and teardown

- (void)setUp
{
    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
}

- (void)tearDown
{
    [self.mediaPlayerController reset];
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testAppleBipBopOnDemandPlaybackStartAtTimeWithTolerances
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:AppleBipBopOnDemandTestURL() atPosition:[SRGPosition positionAroundTimeInSeconds:22.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Check we started near the specified location
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 22, 4);
}

- (void)testRTSWWOnDemandPlaybackStartAtTimeWithTolerances
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:RTSWWOnDemandTestURL() atPosition:[SRGPosition positionAroundTimeInSeconds:22.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Check we started near the specified location
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 22, 4);
}

- (void)testRTSCHOnDemandPlaybackStartAtTimeWithTolerances
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:RTSCHOnDemandTestURL() atPosition:[SRGPosition positionAroundTimeInSeconds:22.] withSegments:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Check we started near the specified location
    TestAssertAlmostEqual(self.mediaPlayerController.currentTime, 22, 4);
}

@end
