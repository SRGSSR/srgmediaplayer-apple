//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SegmentCollectionViewCell : UICollectionViewCell

@property (nonatomic, nullable) Segment *segment;

- (void)updateAppearanceWithTime:(CMTime)time selectedSegment:(nullable Segment *)selectedSegment;

@end

NS_ASSUME_NONNULL_END
