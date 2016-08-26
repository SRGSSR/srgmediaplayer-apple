//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Internal view class for displaying the player
 */
@interface RTSMediaPlayerView : UIView

@property (readonly) AVPlayerLayer *playerLayer;

@end

NS_ASSUME_NONNULL_END
