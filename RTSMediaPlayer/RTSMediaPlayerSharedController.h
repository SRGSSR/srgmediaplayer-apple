//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerController.h"

@class RTSMediaPlayerViewController;

/**
 *  Lightweight internal RTSMediaPlayerController subclass. An instance is shared among all RTSMediaPlayerViewController
 *  instances to managed picture in picture background play
 */
@interface RTSMediaPlayerSharedController : RTSMediaPlayerController <AVPictureInPictureControllerDelegate>

@property (nonatomic, weak) RTSMediaPlayerViewController *currentViewController;

@end
