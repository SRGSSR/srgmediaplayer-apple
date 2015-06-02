//
//  Created by Samuel Défago on 01.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic) CMTimeRange segmentTimeRange;

@property (nonatomic, copy) NSString *title;
@property (nonatomic) UIImage *iconImage;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) NSDate *date;
@property (nonatomic, assign) BOOL blockedSegment;
@property (nonatomic, assign) BOOL visibleSegment;
@property (nonatomic) NSURL *thumbnailURL;

@end

@implementation Segment

#pragma mark - Object lifecycle

- (instancetype) initWithTime:(CMTime)time title:(NSString *)title identifier:(NSString *)identifier date:(NSDate *)date
{
	if (!title || !identifier || !date) {
		return nil;
	}
	
	self = [super init];
	if (self) {
		self.segmentTimeRange = CMTimeRangeMake(time, kCMTimeZero);
		
		NSArray *titleComponents = [title componentsSeparatedByString:@"|"];
		if ([titleComponents count] > 1) {
			self.iconImage = [UIImage imageNamed:[titleComponents firstObject]];
			self.title = [titleComponents objectAtIndex:1];
		}
		else {
			self.title = title;
		}
		
		self.identifier = identifier;
		self.date = date;
	}
	return self;
}

- (instancetype)initWithStartTime:(NSTimeInterval)start duration:(NSTimeInterval)duration title:(NSString *)title blocked:(BOOL)blocked visible:(BOOL)visible
{
	self = [super init];
	if (self) {
		self.segmentTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(start, NSEC_PER_SEC), CMTimeMakeWithSeconds(duration, NSEC_PER_SEC));
		self.title = title;
		self.blockedSegment = blocked;
		self.visibleSegment = visible;
	}
	return self;
}

- (BOOL)isBlocked
{
	return self.blockedSegment;
}

- (BOOL)isVisible
{
	return self.visibleSegment;
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
			@(CMTimeGetSeconds(self.segmentTimeRange.start)),
			self.title,
			self.identifier,
			self.date,
			self.thumbnailURL];
}

@end
