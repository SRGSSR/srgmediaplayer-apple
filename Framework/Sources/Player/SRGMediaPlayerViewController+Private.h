//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface SRGMediaPlayerViewController (Private)

/**
 *  Create a view controller with the current status of the underlying shared controller. Intended for picture in
 *  picture state restoration
 */
- (instancetype)initWithCurrentURLandUserInfo;

@end
