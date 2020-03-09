//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaAccessibility.h"

#import "NSBundle+SRGMediaPlayer.h"

static NSArray<NSString *> *SRGPreferredCaptionLanguageCodes(void);

void SRGMediaAccessibilityCaptionAppearanceAddPreferredLanguages(MACaptionAppearanceDomain domain)
{
    SRGMediaAccessibilityCaptionAppearanceAddSelectedLanguages(domain, SRGPreferredCaptionLanguageCodes());
}

void SRGMediaAccessibilityCaptionAppearanceAddSelectedLanguages(MACaptionAppearanceDomain domain, NSArray<NSString *> *languageCodes)
{
    for (NSString *languageCode in [languageCodes reverseObjectEnumerator]) {
        MACaptionAppearanceAddSelectedLanguage(domain, (__bridge CFStringRef _Nonnull)languageCode);
    }
}

NSString *SRGMediaAccessibilityCaptionAppearanceLastSelectedLanguage(MACaptionAppearanceDomain domain)
{
    NSArray *selectedLanguages = CFBridgingRelease(MACaptionAppearanceCopySelectedLanguages(kMACaptionAppearanceDomainUser));
    return selectedLanguages.firstObject;
}

// List of preferred languages, from the most to the least preferred one
static NSArray<NSString *> *SRGPreferredCaptionLanguageCodes(void)
{
    NSMutableArray<NSString *> *languageCodes = [NSMutableArray array];
    
    // List of preferred languages from the system settings.
    NSArray<NSString *> *preferredLanguages = NSLocale.preferredLanguages;
    for (NSString *language in preferredLanguages) {
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:language];
        [languageCodes addObject:[locale objectForKey:NSLocaleLanguageCode]];
    }
    
    // Add current application language as fallback
    [languageCodes addObject:SRGMediaPlayerApplicationLocalization()];
    
    return languageCodes.copy;
}
