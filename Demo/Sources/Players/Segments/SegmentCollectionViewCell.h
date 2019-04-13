//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaSegment.h"

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SegmentCollectionViewCell : UICollectionViewCell

@property (nonatomic, nullable) MediaSegment *segment;

- (void)updateAppearanceWithTime:(CMTime)time selectedSegment:(nullable MediaSegment *)selectedSegment;

@end

NS_ASSUME_NONNULL_END
