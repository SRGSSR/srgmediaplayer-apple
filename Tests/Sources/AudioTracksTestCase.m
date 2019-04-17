//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"

#import <libextobjc/libextobjc.h>
#import <MediaAccessibility/MediaAccessibility.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface AudioTracksTestCase : MediaPlayerBaseTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation AudioTracksTestCase

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

- (void)testAudioTrackInformationAndKeyValueObserving
{
    XCTAssertNil(self.mediaPlayerController.availableAudioTrackLocalizations);
    XCTAssertNil(self.mediaPlayerController.audioTrackLocalization);
    
    NSArray<NSString *> *expectedLocalizations = @[ @"de", @"fr", @"it", @"rm" ];
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, availableAudioTrackLocalizations) expectedValue:expectedLocalizations];
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) expectedValue:@"fr"];
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.availableAudioTrackLocalizations, expectedLocalizations);
    XCTAssertEqualObjects(self.mediaPlayerController.audioTrackLocalization, @"fr");
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, availableAudioTrackLocalizations) expectedValue:nil];
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) expectedValue:nil];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.availableAudioTrackLocalizations);
    XCTAssertNil(self.mediaPlayerController.audioTrackLocalization);
}

- (void)testAudioTrackInformationAndNotifications
{
    XCTAssertNil(self.mediaPlayerController.audioTrackLocalization);
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil(notification.userInfo[SRGMediaPlayerPreviousTrackKey]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        return YES;
    }];
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.audioTrackLocalization, @"fr");
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        XCTAssertNil(notification.userInfo[SRGMediaPlayerTrackKey]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.audioTrackLocalization);
}

- (void)testAudioTrackChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredAudioTrackLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) expectedValue:@"it"];
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"it");
        return YES;
    }];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = @"it";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"it");
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSameAudioTrackChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredAudioTrackLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No track change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = @"fr";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"fr");
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testAutomaticAudioTrackChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredAudioTrackLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No track change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = SRGMediaPlayerLocalizationAutomatic;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, SRGMediaPlayerLocalizationAutomatic);
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testDefaultAudioTrackChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredAudioTrackLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No track change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = nil;
    XCTAssertNil(self.mediaPlayerController.preferredAudioTrackLocalization);
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testDisabledAudioTrackChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredAudioTrackLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No track change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    // Not supported
    self.mediaPlayerController.preferredAudioTrackLocalization = SRGMediaPlayerLocalizationDisabled;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, SRGMediaPlayerLocalizationDisabled);
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testInvalidAudioTrackChangeFromDefault
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    XCTAssertNil(self.mediaPlayerController.preferredAudioTrackLocalization);
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No track change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = @"ka";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"ka");
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testAudioTrackChangeFromCustom
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = @"de";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"de");
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) expectedValue:@"it"];
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"de");
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"it");
        return YES;
    }];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = @"it";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"it");
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSameAudioTrackChangeFromCustom
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = @"de";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"de");
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No track change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = @"de";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"de");
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testDefaultAudioTrackChangeFromCustom
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = @"de";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"de");
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) expectedValue:@"fr"];
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"de");
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        return YES;
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = nil;
    XCTAssertNil(self.mediaPlayerController.preferredAudioTrackLocalization);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testDisabledAudioTrackChangeFromCustom
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = @"de";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"de");
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    id trackChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No track change notification is expected");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    // Not supported
    self.mediaPlayerController.preferredAudioTrackLocalization = SRGMediaPlayerLocalizationDisabled;
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, SRGMediaPlayerLocalizationDisabled);
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:trackChangeObserver];
    }];
}

- (void)testInvalidAudioTrackChangeFromCustom
{
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return change[NSKeyValueChangeNewKey] != NSNull.null;
    }];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = @"de";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"de");
    
    NSURL *URL = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.mediaPlayerController keyPath:@keypath(SRGMediaPlayerController.new, audioTrackLocalization) expectedValue:@"fr"];
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"de");
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        return YES;
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.preferredAudioTrackLocalization = @"ka";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"ka");
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPreservedPreferredAudioTrackLocalizationBetweenMediaPlaybacks
{
    self.mediaPlayerController.preferredAudioTrackLocalization = @"fr";
    XCTAssertEqualObjects(self.mediaPlayerController.preferredAudioTrackLocalization, @"fr");
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        return YES;
    }];
    
    NSURL *URL1 = [NSURL URLWithString:@"https://rtsvodww-vh.akamaihd.net/i/docfu/2017/docfu_20170728_full_f_1027021-,301k,101k,701k,1201k,2001k,fra-ad,roh,deu,ita,.mp4.csmil/master.m3u8?audiotrack=0:fra:Fran%C3%A7ais,5:fra:Fran%C3%A7ais%20(AD),6:roh:Rh%C3%A9to-roman,7:deu:Allemand,8:ita:Italien&caption=docfu/2017/docfu_20170728_full_f_1027021_fra.m3u8:fra:Fran%C3%A7ais,docfu/2017/docfu_20170728_full_f_1027021_ita.m3u8:ita:Italien,docfu/2017/docfu_20170728_full_f_1027021_gsw.m3u8:deu:Allemand"];
    [self.mediaPlayerController playURL:URL1];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.audioTrackLocalization, @"fr");
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        return YES;
    }];
    
    NSURL *URL2 = [NSURL URLWithString:@"http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v"];
    [self.mediaPlayerController playURL:URL2];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.audioTrackLocalization);
    
    [self expectationForSingleNotification:SRGMediaPlayerAudioTrackDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil([[notification.userInfo[SRGMediaPlayerPreviousTrackKey] locale] objectForKey:NSLocaleLanguageCode]);
        XCTAssertEqualObjects([[notification.userInfo[SRGMediaPlayerTrackKey] locale] objectForKey:NSLocaleLanguageCode], @"fr");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:URL1];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.audioTrackLocalization, @"fr");
}

@end
