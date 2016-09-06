//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return a localized string from the media player resource bundle
 */
#define SRGMediaPlayerLocalizedString(key, comment) [[NSBundle srg_mediaPlayerBundle] localizedStringForKey:(key) value:@"" table:nil]

@interface NSBundle (SRGMediaPlayer)

/**
 *  The media player resource bundle
 */
+ (instancetype)srg_mediaPlayerBundle;

@end

NS_ASSUME_NONNULL_END
