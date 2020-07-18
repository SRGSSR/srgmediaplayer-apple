//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaSegment.h"

@import SRGMediaPlayer;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface SegmentCollectionViewCell : UICollectionViewCell

- (void)setSegment:(nullable MediaSegment *)segment mediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController;

- (void)updateAppearanceWithTime:(CMTime)time selectedSegment:(nullable MediaSegment *)selectedSegment;

@end

NS_ASSUME_NONNULL_END
