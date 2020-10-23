//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import MediaAccessibility;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Update the subtitle language selection stack to best match the current language preferences. This helps the "Closed
 *  Captions + SDH" accessibility feature to find a better match for the user.
 *    https://developer.apple.com/documentation/mediaaccessibility/macaptionappearancedisplaytype/kmacaptionappearancedisplaytypealwayson
 */
OBJC_EXPORT void SRGMediaAccessibilityCaptionAppearanceAddPreferredLanguages(MACaptionAppearanceDomain domain);

/**
 *  Update the subtitle language selection stack with the provided language list. This list is saved at the system level,
 *  and is shard by instances of `AVPlayer` with `appliesMediaSelectionCriteriaAutomatically` (default). This includes
 *  `SRGMediaPlayerController`, but also `AVPlayerViewController` (within the same app) or Safari.
 */
OBJC_EXPORT void SRGMediaAccessibilityCaptionAppearanceAddSelectedLanguages(MACaptionAppearanceDomain domain, NSArray<NSString *> *languageCodes);

/**
 *  Return the current top selected language.
 */
OBJC_EXPORT NSString * _Nullable SRGMediaAccessibilityCaptionAppearanceLastSelectedLanguage(MACaptionAppearanceDomain domain);

NS_ASSUME_NONNULL_END
