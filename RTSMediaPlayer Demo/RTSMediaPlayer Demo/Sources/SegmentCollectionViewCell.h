//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>
#import "Segment.h"

@interface SegmentCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) Segment *segment;

- (void)updateAppearanceWithTime:(CMTime)time;

@end
