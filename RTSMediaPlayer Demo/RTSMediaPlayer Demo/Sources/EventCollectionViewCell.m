//
//  Created by Samuel Défago on 01.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "EventCollectionViewCell.h"

@interface EventCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation EventCollectionViewCell

#pragma mark - Setters and getters

- (void) setEvent:(RTSTimelineEvent *)event
{
	_event = event;
	
	self.titleLabel.text = event.title;
}

@end
