//
//  SegmentCollectionViewCell.h
//  SRGIntegrationLayerDataProvider Demo
//
//  Created by Samuel Defago on 21.05.15.
//  Copyright (c) 2015 SRG. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>
#import "Segment.h"

@interface SegmentCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) Segment *segment;

- (void)updateAppearanceWithTime:(CMTime)time;

@end
