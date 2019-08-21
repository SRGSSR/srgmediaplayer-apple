//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

// Document: Changing the player property leads to undefined behavior
// TODO: Subclassing is not recommended, see https://developer.apple.com/documentation/avkit/avplayerviewcontroller. But
//       we should not do much in the subclass, so this should not hurt
// TODO: Document limitations (e.g. no 360° playback)
// TODO: Document: Controller PiP controller is not used

/**
 *  A lightweight `AVPlayerViewController` subclass, but using an `SRGMediaPlayerController` for playback. A few
 *  limitations should be mentioned:
 *    - You should not alter the `player` property, otherwise the behavior is undefined.
 *    - The `AVPictureInPictureController` used is managed by `AVPlayerViewController` itself and does not correspond
 *      to the one of `SRGMediaPlayerController`.
 */
@interface SRGMediaPlayerViewController : AVPlayerViewController

/**
 *  The controller to use for playback.
 */
@property (nonatomic, readonly) SRGMediaPlayerController *controller;

@end

NS_ASSUME_NONNULL_END
