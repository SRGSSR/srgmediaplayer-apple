//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return a localized string from the media player resource bundle.
 */
#define SRGMediaPlayerLocalizedString(key, comment) [SWIFTPM_MODULE_BUNDLE localizedStringForKey:(key) value:@"" table:nil]

/**
 *  Return an accessibility-oriented localized string from the media player resource bundle.
 */
#define SRGMediaPlayerAccessibilityLocalizedString(key, comment) [SWIFTPM_MODULE_BUNDLE localizedStringForKey:(key) value:@"" table:@"Accessibility"]

/**
 *  Use to avoid user-facing text analyzer warnings.
 *
 *  See https://clang-analyzer.llvm.org/faq.html.
 */
__attribute__((annotate("returns_localized_nsstring")))
OBJC_EXPORT NSString *SRGMediaPlayerNonLocalizedString(NSString *string);

/**
 *  Return the localization used for the application.
 */
OBJC_EXPORT NSString *SRGMediaPlayerApplicationLocalization(void);

NS_ASSUME_NONNULL_END
