//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

// Document: Changing the player property leads to undefined behavior
@interface SRGNativeMediaPlayerViewController : AVPlayerViewController

@property (nonatomic, readonly) SRGMediaPlayerController *controller;

@end

NS_ASSUME_NONNULL_END
