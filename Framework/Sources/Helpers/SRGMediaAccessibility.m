//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaAccessibility.h"

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

NSString *SRGMediaAccessibilityCaptionAppearanceTopSelectedLanguage(MACaptionAppearanceDomain domain)
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
    
    // Add current locale language code as last item. The current locale is the one of the app which best matches
    // system settings (even if it does not appear in the preferred language list). Use it as fallback.
    [languageCodes addObject:[NSLocale.currentLocale objectForKey:NSLocaleLanguageCode]];
    
    return languageCodes.copy;
}
