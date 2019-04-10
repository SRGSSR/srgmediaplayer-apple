//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Lightweight internal `SRGMediaPlayerController` subclass. An instance is shared among all `SRGMediaPlayerViewController`
 *  instances to manage picture in picture background playback.
 */
@interface SRGMediaPlayerSharedController : SRGMediaPlayerController

@end

NS_ASSUME_NONNULL_END

#if TARGET_OS_IOS

NS_ASSUME_NONNULL_BEGIN

@interface SRGMediaPlayerSharedController (PictureInPicture) <AVPictureInPictureControllerDelegate>

@end

NS_ASSUME_NONNULL_END

#endif
