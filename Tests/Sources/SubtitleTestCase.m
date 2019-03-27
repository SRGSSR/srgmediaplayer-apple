//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"

#import <MediaAccessibility/MediaAccessibility.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface SubtitleTestCase : MediaPlayerBaseTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation SubtitleTestCase

#pragma mark Setup and teardown

- (void)setUp
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"en");
    
    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
}

- (void)tearDown
{
    // Always ensure the player gets deallocated between tests
    [self.mediaPlayerController reset];
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testNoTrackNotificationsAtStartupAndWhenReset
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    id audioTrackChangeObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No audio track change at startup is expected");
    }];
    id subtitleTrackChangeObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No subtitle track change at startup is expected");
    }];
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:audioTrackChangeObserver1];
        [NSNotificationCenter.defaultCenter removeObserver:subtitleTrackChangeObserver1];
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    id audioTrackChangeObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No audio track change at reset is expected");
    }];
    id subtitleTrackChangeObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No subtitle track change at reset is expected");
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:audioTrackChangeObserver2];
        [NSNotificationCenter.defaultCenter removeObserver:subtitleTrackChangeObserver2];
    }];
}

- (void)testAudioTrackChangeNotification
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    AVMediaSelectionGroup *selectionGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    
    AVMediaSelectionOption *previousOption = [playerItem selectedMediaOptionInMediaSelectionGroup:selectionGroup];
    XCTAssertNotNil(previousOption);
    
    AVMediaSelectionOption *option = selectionGroup.options.lastObject;
    XCTAssertNotNil(option);
    
    XCTAssertNotEqualObjects(previousOption, option);
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousTrackKey], previousOption);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerTrackKey], option);
        return YES;
    }];
    
    [playerItem selectMediaOption:option inMediaSelectionGroup:selectionGroup];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSubtitleTrackChangeNotification
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    AVMediaSelectionGroup *selectionGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    
    AVMediaSelectionOption *previousOption = [playerItem selectedMediaOptionInMediaSelectionGroup:selectionGroup];
    XCTAssertNil(previousOption);
    
    AVMediaSelectionOption *option1 = selectionGroup.options.lastObject;
    XCTAssertNotNil(option1);
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousTrackKey]);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerTrackKey], option1);
        return YES;
    }];
    
    XCTAssertNotEqualObjects(previousOption, option1);
    [playerItem selectMediaOption:option1 inMediaSelectionGroup:selectionGroup];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    AVMediaSelectionOption *option2 = selectionGroup.options.firstObject;
    XCTAssertNotNil(option2);
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerPreviousTrackKey], option1);
        XCTAssertEqualObjects(notification.userInfo[SRGMediaPlayerTrackKey], option2);
        return YES;
    }];
    
    XCTAssertNotEqualObjects(option1, option2);
    [playerItem selectMediaOption:option2 inMediaSelectionGroup:selectionGroup];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testNoAudioTrackChange
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    AVMediaSelectionGroup *selectionGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    AVMediaSelectionOption *option = [playerItem selectedMediaOptionInMediaSelectionGroup:selectionGroup];
    XCTAssertNotNil(option);
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No track change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [playerItem selectMediaOption:option inMediaSelectionGroup:selectionGroup];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testNoSubtitleTrackChange
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    AVMediaSelectionGroup *selectionGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionOption *option = [playerItem selectedMediaOptionInMediaSelectionGroup:selectionGroup];
    XCTAssertNil(option);
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No track change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [playerItem selectMediaOption:option inMediaSelectionGroup:selectionGroup];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testAvailableLocalizations
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertEqualObjects(self.mediaPlayerController.availableSubtitleLocalizations, @[]);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    NSArray<NSString *> *expectedLocalizations = @[ @"en", @"es", @"fr", @"ja" ];
    XCTAssertEqualObjects(self.mediaPlayerController.availableSubtitleLocalizations, expectedLocalizations);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.availableSubtitleLocalizations, @[]);
}

- (void)testLocalizationsForUserWithForcedOnlySubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"en");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
}

- (void)testLocalizationsForUserWithAutomaticSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"en");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
}

- (void)testLocalizationsForUserWithAlwaysOnSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"ja");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"ja");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
}

- (void)testPreferredLocalizationForUserWithForcedOnlySubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"es";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"es");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"es");
}

- (void)testPreferredLocalizationForUserWithAutomaticSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"es";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"es");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"es");
}

- (void)testPreferredLocalizationForUserWithAlwaysOnSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"ja");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"es";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"es");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"es");
}

- (void)testPreferredUnknownLocalizationForUserWithForcedOnlySubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"unknown";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"unknown");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"en");
}

- (void)testPreferredUnknownLocalizationForUserWithAutomaticSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"unknown";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"unknown");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"en");
}

- (void)testPreferredUnknownLocalizationForUserWithAlwaysOnSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"ja");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"unknown";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"unknown");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"ja");
}

- (void)testPreferredDisabledLocalizationForUserWithForcedOnlySubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = SRGMediaPlayerLocalizationDisabled;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, SRGMediaPlayerLocalizationDisabled);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
}

- (void)testPreferredDisabledLocalizationForUserWithAutomaticSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = SRGMediaPlayerLocalizationDisabled;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, SRGMediaPlayerLocalizationDisabled);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
}

- (void)testPreferredDisabledLocalizationForUserWithAlwaysOnSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"ja");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = SRGMediaPlayerLocalizationDisabled;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, SRGMediaPlayerLocalizationDisabled);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
}

- (void)testPreferredAutomaticLocalizationForUserWithForcedOnlySubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = SRGMediaPlayerLocalizationAutomatic;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, SRGMediaPlayerLocalizationAutomatic);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"en");
}

- (void)testPreferredAutomaticLocalizationForUserWithAutomaticSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = SRGMediaPlayerLocalizationAutomatic;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, SRGMediaPlayerLocalizationAutomatic);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"en");
}

- (void)testPreferredAutomaticLocalizationForUserWithAlwaysOnSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"ja");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = SRGMediaPlayerLocalizationAutomatic;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, SRGMediaPlayerLocalizationAutomatic);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"ja");
}

- (void)testPreferredDefaultLocalizationForUserWithForcedOnlySubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = nil;
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"en");
}

- (void)testPreferredDefaultLocalizationForUserWithAutomaticSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = nil;
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"en");
}

- (void)testPreferredDefaultLocalizationForUserWithAlwaysOnSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"ja");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = nil;
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"ja");
}

- (void)testPreferredLocalizationForStreamWithoutSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"en";
    
    NSURL *URL = [NSURL URLWithString:@"http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
}

- (void)testPreferredLocalizationChangeDuringPlayback
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"ja");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = nil;
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"ja");
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        AVMediaSelectionOption *previousOption = notification.userInfo[SRGMediaPlayerPreviousTrackKey];
        XCTAssertEqualObjects([previousOption.locale objectForKey:NSLocaleLanguageCode], @"ja");
        
        AVMediaSelectionOption *option = notification.userInfo[SRGMediaPlayerTrackKey];
        XCTAssertEqualObjects([option.locale objectForKey:NSLocaleLanguageCode], @"fr");
        return YES;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"fr";
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"fr");
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        AVMediaSelectionOption *previousOption = notification.userInfo[SRGMediaPlayerPreviousTrackKey];
        XCTAssertEqualObjects([previousOption.locale objectForKey:NSLocaleLanguageCode], @"fr");
        
        AVMediaSelectionOption *option = notification.userInfo[SRGMediaPlayerTrackKey];
        XCTAssertEqualObjects([option.locale objectForKey:NSLocaleLanguageCode], @"ja");
        return YES;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = nil;
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"ja");
}

- (void)testPreservedPreferredLocalizationBetweenMediaPlaybacks
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"ja");
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"fr";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"fr");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSURL *URL1 = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL1];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"fr");
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // This media has no subtitles
    NSURL *URL2 = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    [self.mediaPlayerController playURL:URL2];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.mediaPlayerController playURL:URL1];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"fr");
}

@end
