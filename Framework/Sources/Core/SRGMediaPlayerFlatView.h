//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGMediaPlayerFlatView : UIView

@property (nonatomic, nullable) AVPlayer *player;

@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

@end

NS_ASSUME_NONNULL_END
