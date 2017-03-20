//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Private interface for internal use.
 */
@interface SRGMediaPlayerView (Private)

/**
 *  The player layer associated with the view.
 */
@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

@end

NS_ASSUME_NONNULL_END
