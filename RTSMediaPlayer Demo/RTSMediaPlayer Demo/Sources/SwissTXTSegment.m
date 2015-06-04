//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "SwissTXTSegment.h"

#import "SwissTXTDataSource.h"

@interface SwissTXTSegment ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) UIImage *iconImage;
@property (nonatomic) NSDate *date;

@end

@implementation SwissTXTSegment

#pragma mark - Object lifecylce

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange title:(NSString *)title identifier:(NSString *)identifier date:(NSDate *)date
{
	NSString *imageName = nil;
	
	NSArray *titleComponents = [title componentsSeparatedByString:@"|"];
	if ([titleComponents count] > 1)
	{
		imageName = [titleComponents firstObject];
		title = [titleComponents objectAtIndex:1];
	}
	
	if (self = [super initWithTimeRange:timeRange title:title])
	{
		self.identifier = identifier;
		self.date = date;
		if (imageName)
		{
			self.iconImage = [UIImage imageNamed:imageName];
		}
	}
	return self;
}

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange title:(NSString *)title
{
	return [self initWithTimeRange:timeRange title:title identifier:nil date:nil];
}

- (instancetype) initWithTime:(CMTime)time title:(NSString *)title identifier:(NSString *)identifier date:(NSDate *)date
{
	return [self initWithTimeRange:CMTimeRangeMake(time, kCMTimeZero) title:title identifier:identifier date:date];
}

#pragma mark - Getters and setters

- (NSURL *) thumbnailURL
{
	return [SwissTXTDataSource thumbnailURLForIdentifier:self.identifier];
}

@end
