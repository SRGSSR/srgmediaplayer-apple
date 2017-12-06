//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SegmentsPlayerViewController : UIViewController <SRGTimelineSliderDelegate, SRGTimelineViewDelegate, SRGTimeSliderDelegate, UIViewControllerTransitioningDelegate>

- (instancetype)initWithContentURL:(NSURL *)contentURL segments:(nullable NSArray<Segment *> *)segments is360:(BOOL)is360;

@end

NS_ASSUME_NONNULL_END
