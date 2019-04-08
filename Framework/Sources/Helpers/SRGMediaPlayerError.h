//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Media player error codes.
 */
typedef NS_ENUM(NSInteger, SRGMediaPlayerError) {
    /**
     *  Playback error (e.g. playlist could not be read).
     */
    SRGMediaPlayerErrorPlayback,
};

/**
 *  Domain for media player errors.
 */
OBJC_EXPORT NSString * const SRGMediaPlayerErrorDomain;

NS_ASSUME_NONNULL_END
