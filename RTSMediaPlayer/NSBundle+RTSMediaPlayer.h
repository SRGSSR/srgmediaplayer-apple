//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
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
