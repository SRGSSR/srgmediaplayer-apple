//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Lightweight internal `SRGMediaPlayerController` subclass. An instance is shared among all `SRGMediaPlayerViewController`
 *  instances to manage picture in picture background playback
 */
@interface SRGMediaPlayerSharedController : SRGMediaPlayerController <AVPictureInPictureControllerDelegate>

@end

NS_ASSUME_NONNULL_END
