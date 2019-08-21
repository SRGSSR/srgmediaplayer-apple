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
@interface SRGMediaPlayerViewController : AVPlayerViewController

// TODO: Support changes during playback
@property (nonatomic, readonly) SRGMediaPlayerController *controller;

@end

NS_ASSUME_NONNULL_END
