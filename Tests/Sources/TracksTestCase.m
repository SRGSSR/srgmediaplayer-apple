//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"

#import <libextobjc/libextobjc.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface TracksTestCase : MediaPlayerBaseTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation TracksTestCase

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

// TODO: - Meaningful tests (also with asset config block)
//       - Add track documentation to getting started guide (+ styling)

- (void)testAudioTrackNotifications
{
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        return YES;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSubtitlesNotifications
{
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"en");
        return YES;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"en");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testAudioTrackNotificationsWithAssetCustomization
{
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"de");
        return YES;
    }];
    
    self.mediaPlayerController.mediaConfigurationBlock = ^(AVPlayerItem * _Nonnull playerItem, AVAsset * _Nonnull asset) {
        AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:@"de"];
        }];
        NSArray<AVMediaSelectionOption *> *options = [AVMediaSelectionGroup playableMediaSelectionOptionsFromArray:group.options];
        AVMediaSelectionOption *option = [options filteredArrayUsingPredicate:predicate].firstObject;
        if (option) {
            [playerItem selectMediaOption:option inMediaSelectionGroup:group];
        }
    };
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"de");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSubtitlesNotificationsWithAssetCustomization
{
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"ja");
        return YES;
    }];
    
    self.mediaPlayerController.mediaConfigurationBlock = ^(AVPlayerItem * _Nonnull playerItem, AVAsset * _Nonnull asset) {
        AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:@"ja"];
        }];
        NSArray<AVMediaSelectionOption *> *options = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:group.options withoutMediaCharacteristics:@[AVMediaCharacteristicContainsOnlyForcedSubtitles]];
        AVMediaSelectionOption *option = [options filteredArrayUsingPredicate:predicate].firstObject;
        if (option) {
            [playerItem selectMediaOption:option inMediaSelectionGroup:group];
        }
    };
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"ja");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testConfigurationReload
{
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"en");
        return YES;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"en");
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"ja");
        return YES;
    }];
    
    [self.mediaPlayerController reloadMediaConfigurationWithBlock:^(AVPlayerItem * _Nonnull playerItem, AVAsset * _Nonnull asset) {
        AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:@"ja"];
        }];
        NSArray<AVMediaSelectionOption *> *options = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:group.options withoutMediaCharacteristics:@[AVMediaCharacteristicContainsOnlyForcedSubtitles]];
        AVMediaSelectionOption *option = [options filteredArrayUsingPredicate:predicate].firstObject;
        if (option) {
            [playerItem selectMediaOption:option inMediaSelectionGroup:group];
        }
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testConfigurationReloadBeforeMediaIsReady
{
    @weakify(self)
    self.mediaPlayerController.mediaConfigurationBlock = ^(AVPlayerItem * _Nonnull playerItem, AVAsset * _Nonnull asset) {
        @strongify(self)
        XCTFail(@"Media configuration must not be called if the media is not ready");
    };
    
    [self.mediaPlayerController reloadMediaConfiguration];
}

@end
