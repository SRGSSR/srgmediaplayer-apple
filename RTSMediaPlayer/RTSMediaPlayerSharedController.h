//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerController.h"

@class RTSMediaPlayerViewController;

@interface RTSMediaPlayerSharedController : RTSMediaPlayerController <AVPictureInPictureControllerDelegate>

@property (nonatomic, weak) RTSMediaPlayerViewController *currentViewController;

@end
