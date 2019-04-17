//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"

#import <libextobjc/libextobjc.h>
#import <MediaAccessibility/MediaAccessibility.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface SubtitlesTestCase : MediaPlayerBaseTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation SubtitlesTestCase

#pragma mark Setup and teardown

- (void)setUp
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"en");
    
    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
}

- (void)tearDown
{
    [self.mediaPlayerController reset];
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testSubtitleInformationAndKeyValueObserving
{
    XCTAssertNil(self.mediaPlayerController.availableSubtitleLocalizations);
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
    
    NSArray<NSString *> *expectedSubtitleLocalizations = @[ @"en", @"es", @"fr", @"ja" ];
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, availableSubtitleLocalizations) expectedValue:expectedSubtitleLocalizations];
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) expectedValue:@"en"];
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.availableSubtitleLocalizations, expectedSubtitleLocalizations);
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"en");
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, availableSubtitleLocalizations) expectedValue:nil];
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) expectedValue:nil];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.availableSubtitleLocalizations);
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
}

- (void)testSubtitleChangeInformationAndNotifications
{
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousTrackKey]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"en");
        return YES;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"en");
        XCTAssertNil(notification.userInfo[SRGMediaPlayerTrackKey]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSubtitleChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"en");
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"ja");
        return YES;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"ja";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"ja");
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

// FIXME:
- (void)testSameSubtitleChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No subtitle change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"en";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"en");
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testAutomaticSubtitleChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No subtitle change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredSubtitleLocalization = SRGMediaPlayerLocalizationAutomatic;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, SRGMediaPlayerLocalizationAutomatic);
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testDefaultSubtitleChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No subtitle change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredSubtitleLocalization = nil;
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testDisabledSubtitleChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"en");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = SRGMediaPlayerLocalizationDisabled;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, SRGMediaPlayerLocalizationDisabled);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testInvalidSubtitleChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No subtitle change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"ka";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"ka");
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testSubtitleChangeFromCustom
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"es";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"es");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"es");
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"ja");
        return YES;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"ja";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"ja");
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSameSubtitleChangeFromCustom
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"es";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"es");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No subtitle change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"es";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"es");
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testAutomaticSubtitleChangeFromCustom
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"es";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"es");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"es");
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"en");
        return YES;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = SRGMediaPlayerLocalizationAutomatic;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, SRGMediaPlayerLocalizationAutomatic);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testDefaultSubtitleChangeFromCustom
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"es";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"es");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"es");
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"en");
        return YES;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = nil;
    XCTAssertNil(self.mediaPlayerController.preferredSubtitleLocalization);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testDisabledSubtitleChangeFromCustom
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"es";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"es");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"es");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = SRGMediaPlayerLocalizationDisabled;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, SRGMediaPlayerLocalizationDisabled);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testInvalidSubtitleChangeFromCustom
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"es";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"es");
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"es");
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"en");
        return YES;
    }];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"ka";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"ka");
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testInitialSubtitleLocalizationForUserWithForcedOnlySubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"en");
}

- (void)testInitialSubtitleLocalizationForUserWithAutomaticSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"en");
}

- (void)testInitialSubtitleLocalizationForUserWithAlwaysOnSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)@"ja");
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, subtitleLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"ja");
}

- (void)testPreferredSubtitleLocalizationForStreamWithoutSubtitles
{
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No subtitle change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredSubtitleLocalization = @"en";
    
    NSURL *URL = [NSURL URLWithString:@"http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
}

- (void)testPreservedPreferredSubtitleLocalizationBetweenMediaPlaybacks
{
    self.mediaPlayerController.preferredSubtitleLocalization = @"fr";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredSubtitleLocalization, @"fr");
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        return YES;
    }];
    
    NSURL *URL1 = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    [self.mediaPlayerController playURL:URL1];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"fr");
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {        
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    // This media has no subtitles
    NSURL *URL2 = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    [self.mediaPlayerController playURL:URL2];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.subtitleLocalization);
    
    [self expectationForSingleNotification:SRGMediaPlayerSubtitlesDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:URL1];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.subtitleLocalization, @"fr");
}

@end
