//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVMediaSelectionGroup (SRGMediaPlayer)

/**
 *  Same as the `options` property, but only returning options with a valid language code.
 */
@property (nonatomic, readonly) NSArray<AVMediaSelectionOption *> *srgmediaplayer_languageOptions;

@end

NS_ASSUME_NONNULL_END
