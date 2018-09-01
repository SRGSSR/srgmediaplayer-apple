//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemoSegment.h"

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SegmentCollectionViewCell : UICollectionViewCell

@property (nonatomic, nullable) DemoSegment *segment;

- (void)updateAppearanceWithTime:(CMTime)time selectedSegment:(nullable DemoSegment *)selectedSegment;

@end

NS_ASSUME_NONNULL_END
