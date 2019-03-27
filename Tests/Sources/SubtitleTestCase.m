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
