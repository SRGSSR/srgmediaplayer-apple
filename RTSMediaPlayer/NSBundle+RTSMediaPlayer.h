//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>

#define RTSMediaPlayerLocalizedString(key, comment) [[NSBundle RTSMediaPlayerBundle] localizedStringForKey:(key) value:@"" table:nil]

@interface NSBundle (RTSMediaPlayer)

+ (instancetype) RTSMediaPlayerBundle;

@end
