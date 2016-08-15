//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

/**
 *  Return a localized string from the media player resource bundle
 */
#define RTSMediaPlayerLocalizedString(key, comment) [[NSBundle RTSMediaPlayerBundle] localizedStringForKey:(key) value:@"" table:nil]

@interface NSBundle (RTSMediaPlayer)

/**
 *  The media player resource bundle
 */
+ (instancetype) RTSMediaPlayerBundle;

@end
