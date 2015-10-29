//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>
#import "Segment.h"

@interface SegmentCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) Segment *segment;

- (void)updateAppearanceWithTime:(CMTime)time identifier:(NSString *)identifier;

@end
