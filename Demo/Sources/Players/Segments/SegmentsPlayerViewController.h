//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Media.h"

@import SRGMediaPlayer;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface SegmentsPlayerViewController : UIViewController <SRGTimelineViewDelegate, SRGTimeSliderDelegate, UIViewControllerTransitioningDelegate>

- (instancetype)initWithMedia:(Media *)media;

@end

NS_ASSUME_NONNULL_END
