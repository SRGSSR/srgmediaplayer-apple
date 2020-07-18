//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"

@import libextobjc;
@import MediaAccessibility;
@import SRGMediaPlayer;

// Private headers
@interface SRGMediaPlayerController (Private)

- (nullable AVMediaSelectionOption *)selectedMediaOptionInMediaSelectionGroupWithCharacteristic:(AVMediaCharacteristic)characteristic;

@end

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

#pragma mark Helpers

- (NSString *)selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:(AVMediaCharacteristic)characteristic
{
    AVMediaSelectionOption *option = [self.mediaPlayerController selectedMediaOptionInMediaSelectionGroupWithCharacteristic:characteristic];
    return [option.locale objectForKey:NSLocaleLanguageCode];
}

#pragma mark Tests

- (void)testAudioTrackNotifications
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    XCTAssertNil([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible]);
    XCTAssertNil([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible]);
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        return YES;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021,-1201k,-701k,-301k,-101k,-2001k,-fra-ad,-roh,-deu,-ita,.mp4.csmil/master.m3u8?audiotrack=0:fr:Fran%C3%A7ais,5:fr:Fran%C3%A7ais%20(AD):ad,6:rm:Rumantsch,7:de:Deutsch,8:it:Italiano&subtitles=it,gsw,fr:sdh"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    XCTAssertEqualObjects([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible], @"fr");
    XCTAssertNil([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible]);
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSubtitlesNotifications
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"fr");
    
    XCTAssertNil([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible]);
    XCTAssertNil([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible]);
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        return YES;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021,-1201k,-701k,-301k,-101k,-2001k,-fra-ad,-roh,-deu,-ita,.mp4.csmil/master.m3u8?audiotrack=0:fr:Fran%C3%A7ais,5:fr:Fran%C3%A7ais%20(AD):ad,6:rm:Rumantsch,7:de:Deutsch,8:it:Italiano&subtitles=it,gsw,fr:sdh"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    XCTAssertEqualObjects([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible], @"fr");
    XCTAssertEqualObjects([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible], @"fr");
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testAudioTrackNotificationsWithAudioConfiguration
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    XCTAssertNil([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible]);
    XCTAssertNil([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible]);
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"de");
        return YES;
    }];
    
    self.mediaPlayerController.audioConfigurationBlock = ^AVMediaSelectionOption * _Nonnull(NSArray<AVMediaSelectionOption *> * _Nonnull audioOptions, AVMediaSelectionOption * _Nonnull defaultAudioOption) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:@"de"];
        }];
        return [audioOptions filteredArrayUsingPredicate:predicate].firstObject ?: defaultAudioOption;
    };
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021,-1201k,-701k,-301k,-101k,-2001k,-fra-ad,-roh,-deu,-ita,.mp4.csmil/master.m3u8?audiotrack=0:fr:Fran%C3%A7ais,5:fr:Fran%C3%A7ais%20(AD):ad,6:rm:Rumantsch,7:de:Deutsch,8:it:Italiano&subtitles=it,gsw,fr:sdh"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"de");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    XCTAssertEqualObjects([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible], @"de");
    XCTAssertNil([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible]);
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSubtitlesNotificationsWithSubtitleConfiguration
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    XCTAssertNil([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible]);
    XCTAssertNil([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible]);
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"ja");
        return YES;
    }];
    
    self.mediaPlayerController.subtitleConfigurationBlock = ^AVMediaSelectionOption * _Nullable(NSArray<AVMediaSelectionOption *> * _Nonnull subtitleOptions, AVMediaSelectionOption * _Nullable audioOption, AVMediaSelectionOption * _Nullable defaultSubtitleOption) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:@"ja"];
        }];
        return [subtitleOptions filteredArrayUsingPredicate:predicate].firstObject ?: defaultSubtitleOption;
    };
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"ja");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    XCTAssertEqualObjects([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible], @"en");
    XCTAssertEqualObjects([self selectedLanguageCodeInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible], @"ja");
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSubtitleStyleCustomization
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    AVTextStyleRule *rule = [[AVTextStyleRule alloc] initWithTextMarkupAttributes:@{ (id)kCMTextMarkupAttribute_ForegroundColorARGB : @[ @1, @1, @0, @0 ],
                                                                                     (id)kCMTextMarkupAttribute_ItalicStyle : @(YES)}];
    NSArray<AVTextStyleRule *> *rules = @[rule];
    self.mediaPlayerController.textStyleRules = rules;
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.textStyleRules, rules);
    XCTAssertEqualObjects(self.mediaPlayerController.player.currentItem.textStyleRules, rules);
}

- (void)testMediaConfigurationReloadDuringPlayback
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitleTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"ja");
        return YES;
    }];
    
    self.mediaPlayerController.subtitleConfigurationBlock = ^AVMediaSelectionOption * _Nullable(NSArray<AVMediaSelectionOption *> * _Nonnull subtitleOptions, AVMediaSelectionOption * _Nullable audioOption, AVMediaSelectionOption * _Nullable defaultSubtitleOption) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:@"ja"];
        }];
        return [subtitleOptions filteredArrayUsingPredicate:predicate].firstObject ?: defaultSubtitleOption;
    };
    [self.mediaPlayerController reloadMediaConfiguration];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testMediaConfigurationReloadBeforeMediaIsReady
{
    @weakify(self)
    self.mediaPlayerController.audioConfigurationBlock = ^AVMediaSelectionOption * _Nonnull(NSArray<AVMediaSelectionOption *> * _Nonnull audioOptions, AVMediaSelectionOption * _Nonnull defaultAudioOption) {
        @strongify(self)
        XCTFail(@"Audio configuration block must not be called before the media is ready");
        return defaultAudioOption;
    };
    self.mediaPlayerController.subtitleConfigurationBlock = ^AVMediaSelectionOption * _Nullable(NSArray<AVMediaSelectionOption *> * _Nonnull subtitleOptions, AVMediaSelectionOption * _Nullable audioOption, AVMediaSelectionOption * _Nullable defaultSubtitleOption) {
        @strongify(self)
        XCTFail(@"Subtitle configuration block must not be called before the media is ready");
        return defaultSubtitleOption;
    };
    [self.mediaPlayerController reloadMediaConfiguration];
}

@end
