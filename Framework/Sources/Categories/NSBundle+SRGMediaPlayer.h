//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return a localized string from the media player resource bundle.
 */
#define SRGMediaPlayerLocalizedString(key, comment) [NSBundle.srg_mediaPlayerBundle localizedStringForKey:(key) value:@"" table:nil]

/**
 *  Return an accessibility-oriented localized string from the media player resource bundle.
 */
#define SRGMediaPlayerAccessibilityLocalizedString(key, comment) [NSBundle.srg_mediaPlayerBundle localizedStringForKey:(key) value:@"" table:@"Accessibility"]

/**
 *  Use to avoid user-facing text analyzer warnings.
 *
 *  See https://clang-analyzer.llvm.org/faq.html.
 */
__attribute__((annotate("returns_localized_nsstring")))
OBJC_EXPORT NSString *SRGMediaPlayerNonLocalizedString(NSString *string);

@interface NSBundle (SRGMediaPlayer)

/**
 *  The media player resource bundle.
 */
@property (class, nonatomic, readonly) NSBundle *srg_mediaPlayerBundle;

@end

NS_ASSUME_NONNULL_END
