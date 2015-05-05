//
//  Created by Samuel Défago on 01.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "EventCollectionViewCell.h"

#import <SDWebImage/UIImageView+WebCache.h>

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
	
	static NSDateFormatter *s_dateFormatter;
	static dispatch_once_t s_onceToken;
	dispatch_once(&s_onceToken, ^{
		s_dateFormatter = [[NSDateFormatter alloc] init];
		[s_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[s_dateFormatter setDateStyle:NSDateFormatterNoStyle];
	});
	self.timestampLabel.text = [NSString stringWithFormat:@"at %@", [s_dateFormatter stringFromDate:event.date]];
	
	[self.imageView sd_setImageWithURL:event.imageURL];
}

@end
