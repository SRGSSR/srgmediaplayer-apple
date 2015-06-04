//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "SwissTXTSegmentCollectionViewCell.h"

@interface SwissTXTSegmentCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;

@end

@implementation SwissTXTSegmentCollectionViewCell

#pragma mark - Getters and setters

- (SwissTXTSegment *)segment
{
	return (SwissTXTSegment *)super.segment;
}

- (void)setSegment:(SwissTXTSegment *)segment
{
	super.segment = segment;
	
	self.iconImageView.image = segment.iconImage;	
}

@end
