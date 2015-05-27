//
//  Created by Samuel Défago on 01.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic) CMTime segmentStartTime;
@property (nonatomic) CMTime segmentEndTime;
@property (nonatomic) UIImage *segmentIconImage;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) NSDate *date;

@property (nonatomic) NSURL *thumbnailURL;

@end

@implementation Segment

#pragma mark - Object lifecycle

- (instancetype) initWithTime:(CMTime)time title:(NSString *)title identifier:(NSString *)identifier date:(NSDate *)date
{
	if (!title || !identifier || !date)
	{
		return nil;
	}
	
	if (self = [super init])
	{
		self.segmentStartTime = time;
		self.segmentEndTime = time;
		
		NSArray *titleComponents = [title componentsSeparatedByString:@"|"];
		if ([titleComponents count] > 1)
		{
			self.segmentIconImage = [UIImage imageNamed:[titleComponents firstObject]];
			self.title = [titleComponents objectAtIndex:1];
		}
		else
		{
			self.title = title;
		}
		
		self.identifier = identifier;
		self.date = date;
	}
	return self;
}

#pragma mark - Getters and setters

- (NSURL *) thumbnailURL
{
	NSString *thumbnailURLString = [NSString stringWithFormat:@"http://test.event.api.swisstxt.ch:80/v1/image/byId/%@", self.identifier];
	return [NSURL URLWithString:thumbnailURLString];
}

#pragma mark - Description

- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@: %p; time: %@; title: %@; identifier: %@; date: %@; thumbnailURL: %@>",
			[self class],
			self,
			@(CMTimeGetSeconds(self.segmentStartTime)),
			self.title,
			self.identifier,
			self.date,
			self.thumbnailURL];
}

@end
