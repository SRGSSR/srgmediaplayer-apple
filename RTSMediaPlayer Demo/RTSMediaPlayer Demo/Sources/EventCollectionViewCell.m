//
//  Created by Samuel Défago on 01.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "EventCollectionViewCell.h"

#import <SDWebImage/UIImageView+WebCache.h>

NSString *StringFromTime(CMTime time);

@interface EventCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *timestampLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation EventCollectionViewCell

#pragma mark - Setters and getters

- (void) setEvent:(Event *)event
{
	_event = event;
	
	self.titleLabel.text = event.title;
	self.timestampLabel.text = StringFromTime(event.time);
	
	[self.imageView sd_setImageWithURL:event.imageURL];
}

@end

#pragma mark - Functions

NSString *StringFromTime(CMTime time)
{
	if (!CMTIME_IS_VALID(time))
	{
		return @"--:--";
	}
	
	NSInteger timeInSeconds = CMTimeGetSeconds(time);
	NSInteger hours = timeInSeconds / (60 * 60);
	NSInteger minutes = (timeInSeconds - hours * 60 * 60) / 60;
	NSInteger seconds = timeInSeconds - hours * 60 * 60 - minutes * 60;
	
	if (hours > 0)
	{
		return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
	}
	else
	{
		return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
	}
}
